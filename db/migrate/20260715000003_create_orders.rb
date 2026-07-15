class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_enum :order_status, %w[created success cancelled]

    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.enum :status, enum_type: :order_status, default: "created", null: false

      t.timestamps
    end
  end
end
