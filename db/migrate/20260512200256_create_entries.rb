class CreateEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :entries do |t|
      t.references :account, null: false, foreign_key: true
      t.references :ledger_transaction, null: false, foreign_key: true
      t.bigint :amount_cents
      t.string :entry_type

      t.timestamps
    end
  end
end
