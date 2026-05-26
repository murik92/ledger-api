class AddRequestFingerprintToLedgerTransactions < ActiveRecord::Migration[7.1]
  def change
    add_column :ledger_transactions,
               :request_fingerprint,
               :string

    add_index :ledger_transactions,
              :request_fingerprint
  end
end
