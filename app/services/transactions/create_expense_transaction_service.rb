class Transactions::CreateExpenseTransactionService
  def self.call(
    user:,
    category:,
    note:
  )
    unless category.category_type_expense?
      raise ArgumentError, "Category must be expense type"
    end

    ledger_transaction = LedgerTransaction.create!(
      reference: SecureRandom.uuid,
      status: "completed",
      idempotency_key: SecureRandom.uuid,
      request_fingerprint: SecureRandom.uuid
    )

    CategorizedTransaction.create!(
      user: user,
      category: category,
      ledger_transaction: ledger_transaction,
      transaction_type: "expense",
      note: note
    )
  end
end
