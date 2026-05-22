class AddDatabaseConstraints < ActiveRecord::Migration[7.1]
  def change
    add_check_constraint(
      :accounts,
      "opening_balance_cents >= 0",
      name: "accounts_opening_balance_non_negative"
    )

    add_check_constraint(
      :entries,
      "entry_type IN ('debit', 'credit')",
      name: "entries_valid_entry_type"
    )

    add_check_constraint(
      :ledger_transactions,
      "status IN ('pending', 'completed', 'failed')",
      name: "ledger_transactions_valid_status"
    )
  end
end