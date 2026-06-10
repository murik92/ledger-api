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

      income_cents =
        transactions
          .where(
            transaction_type: "income"
          )
          .joins(:ledger_transaction)
          .sum(
            "ledger_transactions.amount_cents"
          )

      expense_cents =
        transactions
          .where(
            transaction_type: "expense"
          )
          .joins(:ledger_transaction)
          .sum(
            "ledger_transactions.amount_cents"
          )

      {
        month: month,
        income_cents: income_cents,
        expense_cents: expense_cents,
        balance_cents:
          income_cents - expense_cents
      }
    end
  end
end
