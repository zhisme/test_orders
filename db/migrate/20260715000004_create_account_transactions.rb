class CreateAccountTransactions < ActiveRecord::Migration[8.1]
  def change
    create_enum :transaction_kind, %w[charge refund]

    create_table :account_transactions do |t|
      t.references :account, null: false, foreign_key: true
      t.references :order, null: true, foreign_key: true
      t.integer :amount_cents, null: false
      t.enum :kind, enum_type: :transaction_kind, null: false

      t.timestamps
    end
  end
end
