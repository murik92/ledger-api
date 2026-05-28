class CreateCategorizedTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :categorized_transactions do |t|
      t.references :user,
                   null: false,
                   foreign_key: true

      t.references :ledger_transaction,
                   null: false,
                   foreign_key: true

      t.references :category,
                   null: false,
                   foreign_key: true

      t.string :transaction_type,
               null: false

      t.text :note

      t.timestamps
    end

    add_index(
      :categorized_transactions,
      :ledger_transaction_id,
      unique: true,
      name: "index_unique_categorized_transaction"
    )
  end
end
