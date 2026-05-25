class AddDatabaseInvariants < ActiveRecord::Migration[7.1]
  def up
    change_column_null :accounts, :balance_cents, false
    change_column_null :accounts, :currency, false

    change_column_null :entries, :amount_cents, false
    change_column_null :entries, :entry_type, false

    change_column_null :ledger_transactions, :reference, false
    change_column_null :ledger_transactions, :status, false

    add_check_constraint(
      :accounts,
      "name = 'SYSTEM' OR balance_cents >= 0",
      name: "accounts_balance_non_negative"
    )

    add_check_constraint(
      :entries,
      "amount_cents <> 0",
      name: "entries_amount_non_zero"
    )
  end

  def down
    remove_check_constraint(
      :accounts,
      name: "accounts_balance_non_negative"
    )

    remove_check_constraint(
      :entries,
      name: "entries_amount_non_zero"
    )

    change_column_null :accounts, :balance_cents, true
    change_column_null :accounts, :currency, true

    change_column_null :entries, :amount_cents, true
    change_column_null :entries, :entry_type, true

    change_column_null :ledger_transactions, :reference, true
    change_column_null :ledger_transactions, :status, true
  end
end
