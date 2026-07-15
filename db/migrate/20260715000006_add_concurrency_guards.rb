# frozen_string_literal: true

class AddConcurrencyGuards < ActiveRecord::Migration[8.1]
  def change
    # At most one charge and one refund per order, enforced at the DB.
    # Backstops the application-level lock against double charge/refund.
    add_index :account_transactions, %i[order_id kind],
              unique: true,
              where: "kind IN ('charge', 'refund')",
              name: 'idx_unique_charge_refund_per_order'

    add_check_constraint :orders, 'amount_cents > 0', name: 'orders_amount_positive'
    add_check_constraint :account_transactions, 'amount_cents <> 0', name: 'account_transactions_amount_nonzero'
  end
end
