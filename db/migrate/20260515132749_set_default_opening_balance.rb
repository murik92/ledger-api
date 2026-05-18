class SetDefaultOpeningBalance < ActiveRecord::Migration[7.1]
  class Account < ApplicationRecord
    self.table_name = "accounts"
  end

  def change
    change_column_default :accounts,
                          :opening_balance_cents,
                          0

    Account.update_all(opening_balance_cents: 0)

    change_column_null :accounts,
                       :opening_balance_cents,
                       false
  end
end