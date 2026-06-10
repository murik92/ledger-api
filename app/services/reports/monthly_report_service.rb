# app/services/reports/monthly_report_service.rb

module Reports
  class MonthlyReportService
    def self.call(user:, month:)
      start_date =
        Date.parse("#{month}-01")
            .beginning_of_month

      end_date =
        start_date.end_of_month

      transactions =
        CategorizedTransaction
          .where(user: user)
          .where(
            created_at:
              start_date..end_date
          )

      income_count =
        transactions
          .income
          .count

      expense_count =
        transactions
          .expenses
          .count

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
        month: month,
        income_transactions: income_count,
        expense_transactions: expense_count,
        income_cents: income_cents,
        expense_cents: expense_cents,
        net_cashflow_cents:
          income_cents - expense_cents
      }
    end
  end
end
