class AddIdempotencyKeyToLedgerTransactions < ActiveRecord::Migration[7.1]
  def change
    add_column :ledger_transactions,
               :idempotency_key,
               :string

    add_index :ledger_transactions,
              :idempotency_key,
              unique: true
  end
end
