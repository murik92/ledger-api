class CreateLedgerTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :ledger_transactions do |t|
      t.string :reference
      t.string :status

      t.timestamps
    end
  end
end
