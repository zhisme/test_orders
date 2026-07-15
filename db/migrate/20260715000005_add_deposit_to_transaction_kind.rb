class AddDepositToTransactionKind < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    execute "ALTER TYPE transaction_kind ADD VALUE IF NOT EXISTS 'deposit'"
  end

  def down
    # Postgres has no DROP VALUE for enums; would require recreating the type.
    raise ActiveRecord::IrreversibleMigration
  end
end
