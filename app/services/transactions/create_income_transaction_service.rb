class Transactions::CreateIncomeTransactionService
  def self.call(
    user:,
    wallet:,
    category:,
    amount_cents:,
    note:
  )
    unless category.category_type_income?
      raise ArgumentError, "Category must be income type"
    end

    if wallet.user != user
      raise ArgumentError, "Wallet does not belong to user"
    end

    ledger_transaction = LedgerTransaction.create!(
      reference: SecureRandom.uuid,
      status: "completed",
      idempotency_key: SecureRandom.uuid,
      request_fingerprint: SecureRandom.uuid
    )

    wallet.account.increment!(
      :balance_cents,
      amount_cents
    )

    CategorizedTransaction.create!(
      user: user,
      category: category,
      ledger_transaction: ledger_transaction,
      transaction_type: "income",
      note: note
    )
  end
end
