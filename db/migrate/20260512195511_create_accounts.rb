class CreateAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :accounts do |t|
      t.string :name
      t.bigint :balance_cents
      t.string :currency

      t.timestamps
    end
  end
end
