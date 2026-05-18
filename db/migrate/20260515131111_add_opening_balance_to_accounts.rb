class AddOpeningBalanceToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :opening_balance_cents, :bigint
  end
end
