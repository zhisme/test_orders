# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_15_000007) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "order_status", ["created", "success", "cancelled"]
  create_enum "transaction_kind", ["charge", "refund", "deposit"]

  create_table "account_transactions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.enum "kind", null: false, enum_type: "transaction_kind"
    t.bigint "order_id"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_account_transactions_on_account_id"
    t.index ["order_id", "kind"], name: "idx_unique_charge_refund_per_order", unique: true, where: "(kind = ANY (ARRAY['charge'::transaction_kind, 'refund'::transaction_kind]))"
    t.index ["order_id"], name: "index_account_transactions_on_order_id"
    t.check_constraint "amount_cents <> 0", name: "account_transactions_amount_nonzero"
  end

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_accounts_on_user_id", unique: true
  end

  create_table "orders", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "idempotency_key"
    t.enum "status", default: "created", null: false, enum_type: "order_status"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["idempotency_key"], name: "index_orders_on_idempotency_key", unique: true
    t.index ["user_id"], name: "index_orders_on_user_id"
    t.check_constraint "amount_cents > 0", name: "orders_amount_positive"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "account_transactions", "accounts"
  add_foreign_key "account_transactions", "orders"
  add_foreign_key "accounts", "users"
  add_foreign_key "orders", "users"
end
