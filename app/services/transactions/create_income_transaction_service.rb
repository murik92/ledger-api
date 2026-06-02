class Transactions::CreateIncomeTransactionService
  def self.call(
    user:,
    wallet:,
    category:,
    amount_cents:,
    note:,
    idempotency_key:
  )
    unless category.category_type_income?
      raise ArgumentError, "Category must be income type"
    end

    if wallet.user != user
      raise ArgumentError, "Wallet does not belong to user"
    end

    existing_transaction =
      LedgerTransaction.find_by(
        idempotency_key: idempotency_key
      )

    return existing_transaction if existing_transaction

    ledger_transaction = LedgerTransaction.create!(
      reference: SecureRandom.uuid,
      status: "completed",
      idempotency_key: idempotency_key,
      request_fingerprint: SecureRandom.uuid
    )

    wallet.account.reload

    wallet.account.update!(
      balance_cents:
        wallet.account.balance_cents + amount_cents
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
