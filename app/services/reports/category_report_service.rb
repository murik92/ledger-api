module Reports
  class CategoryReportService
    def self.call(user:, from:, to:, transaction_type:)
      transactions =
        CategorizedTransaction
          .where(user: user)
          .where(transaction_type: transaction_type)
          .where(created_at: from..to)

      account_id =
        if transaction_type == "income"
          Account.income_account.id
        else
          Account.expense_account.id
        end

      transactions
        .joins(:category)
        .joins(
          ledger_transaction: :entries
        )
        .where(
          entries: {
            account_id: account_id
          }
        )
        .group("categories.name")
        .sum("ABS(entries.amount_cents)")
        .map do |category_name, amount|
          {
            category: category_name,
            amount_cents: amount
          }
        end
    end
  end
end
