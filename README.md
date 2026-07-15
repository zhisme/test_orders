# Orders / Accounts API

## Описание

Тестовое на Rails 8 (API-only). Заказы принадлежат юзерам, у юзеров account с
балансом. Complete заказа (`created → success`) проводит транзакцию по счёту,
cancel (`success → cancelled`) её сторнирует.

## Задача
>Предположим есть Заказы
>Заказы принадлежат юзерам
>У заказов статусы, что то типо создано, успешный, отменен
>У юзеров есть счета (с балансом)
>При переводе созданного заказа в успех проводим транзакцию по счету, баланс правим
>При отмене уже успешного заказа сторнируем транзакцию, баланс правим.

## Архитектура

- Осознанно не выбраны dryrb/trailblazer/monads/active_interaction и тп, простые руби объекты, читаемый простой код.
- **Баланс — это ledger.** У `Account` нет поля `balance`.
  `balance_cents` = сумма `account_transactions.amount_cents`. Сторно — новая
  обратная запись (`refund`), никаких `UPDATE` по полю. Отсюда аудит и
  reversibility из коробки.
- **Статус заказа — обычный `pg_enum` + guard в сервисе.** Без state-machine гемов,
  все переходы видны глазами. Доменные ошибки собраны в `Orders::Errors`
  (`InvalidTransition` → 422, `Conflict` → 409, `InsufficientFunds` → 422).
- **Бизнес-логика в plain ruby-сервисах** (`Orders::Complete`, `Orders::Cancel`, оба
  `.call`). Тонкие контроллеры → сервисы → модели. Доменные ошибки — обычные
  исключения, ловятся в `ApplicationController`, отдаются как `422`.
- **Деньги — integer cents.** Никаких float, никакого `money-rails`.
- **Prepaid-семантика.** Заказ — это списание с предоплаченного баланса. Сначала
  `deposit` (пополнение, положительная запись `deposit`), потом complete. Если
  баланса не хватает — `Orders::InsufficientFunds` → `422`, charge не пишется.
- **Row lock на денежных операциях.** Каждый сервис берёт `account.lock!`
  (`SELECT ... FOR UPDATE`) внутри транзакции — чтобы race condition не проводили заказ
  дважды.
- **PostgreSQL** с нативными enum-типами (`create_enum`) для `order_status` и
  `transaction_kind`.

Знак: `deposit` = `+amount` (пополнение), `charge` = `-amount_cents` (списание при
complete), `refund` = обратная запись при cancel. Держим консистентно.

## Setup

```bash
bundle install
bin/rails db:setup      # create + migrate + seed
bundle exec rspec       # тесты
bundle exec rubocop     # линт
```

## Endpoints

```
POST /orders                { order: { user_id, amount_cents } }  → 201, созданный заказ
GET  /orders/:id            → заказ
POST /orders/:id/complete   → created → success (пишет charge)
POST /orders/:id/cancel     → success → cancelled (пишет refund)
GET  /accounts/:id          → { id, user_id, balance_cents }
POST /accounts/:id/deposit  { deposit: { amount_cents } }  → пополнение баланса
```

Ошибки (все — `{ "error": "..." }`):

- `422` — невалидный переход (напр. cancel `created` заказа), нехватка средств,
  неположительный deposit.
- `409` — заказ уже в целевом статусе (повторный complete/cancel). Идемпотентно:
  повтор того же запроса безопасен, дублей в ledger нет.
- `404` — нет записи.
- `503` — БД под нагрузкой: lock не взялся за `lock_timeout` (5s, см.
  `database.yml`), statement timeout или пул коннектов исчерпан. Отдаём
  `Retry-After: 5` — клиенту сказано повторить позже.

## Готовый curl запросы

Сиды дают каждому счёту стартовый deposit `10000`.

```bash
curl localhost:3000/accounts/1            # balance_cents: 10000 (сид)
curl -XPOST localhost:3000/accounts/1/deposit -H 'Content-Type: application/json' \
  -d '{"deposit":{"amount_cents":5000}}'  # balance_cents: 15000
curl -XPOST localhost:3000/orders -H 'Content-Type: application/json' \
  -d '{"order":{"user_id":1,"amount_cents":1500}}'
curl -XPOST localhost:3000/orders/1/complete
curl localhost:3000/accounts/1            # balance_cents: 13500
curl -XPOST localhost:3000/orders/1/cancel
curl localhost:3000/accounts/1            # balance_cents: 15000
curl -XPOST localhost:3000/orders/1/cancel # 422, уже отмененный. ошибка
```
