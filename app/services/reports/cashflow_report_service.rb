module Reports
  class CashflowReportService
    def self.call(user:, from:, to:)
      transactions =
        CategorizedTransaction
          .where(user: user)
          .where(created_at: from..to)

      income_cents =
        transactions
          .income
          .joins(
            ledger_transaction: :entries
          )
          .where(
            entries: {
              account_id:
                Account.income_account.id
            }
          )
          .sum(
            "ABS(entries.amount_cents)"
          )

      expense_cents =
        transactions
          .expenses
          .joins(
            ledger_transaction: :entries
          )
          .where(
            entries: {
              account_id:
                Account.expense_account.id
            }
          )
          .sum(
            "ABS(entries.amount_cents)"
          )

      {
        from: from,
        to: to,
        income_cents: income_cents,
        expense_cents: expense_cents,
        net_cashflow_cents:
          income_cents - expense_cents
      }
    end
  end
end
