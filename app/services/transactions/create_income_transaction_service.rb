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

    if existing_transaction
      return CategorizedTransaction.find_by!(
        ledger_transaction: existing_transaction
      )
    end

    ActiveRecord::Base.transaction do
      wallet.account.lock!

      income_account =
        Account.income_account

      ledger_transaction =
        LedgerTransaction.create!(
          reference: SecureRandom.uuid,
          status: "completed",
          idempotency_key: idempotency_key,
          request_fingerprint: SecureRandom.uuid
        )

      Entry.create!(
        account: income_account,
        ledger_transaction: ledger_transaction,
        amount_cents: -amount_cents,
        entry_type: "debit"
      )

      Entry.create!(
        account: wallet.account,
        ledger_transaction: ledger_transaction,
        amount_cents: amount_cents,
        entry_type: "credit"
      )

      wallet.account.update!(
        balance_cents:
          wallet.account.balance_cents + amount_cents
      )

      categorized_transaction =
      CategorizedTransaction.create!(
        user: user,
        category: category,
        ledger_transaction: ledger_transaction,
        transaction_type: "income",
        note: note
      )

    categorized_transaction
    end
  end
end
