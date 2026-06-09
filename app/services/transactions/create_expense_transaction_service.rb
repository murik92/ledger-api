class Transactions::CreateExpenseTransactionService
  def self.call(
    user:,
    wallet:,
    category:,
    amount_cents:,
    note:,
    idempotency_key:
  )

    unless category.category_type_expense?
      raise ArgumentError, "Category must be expense type"
    end

    if wallet.user != user
      raise ArgumentError, "Wallet does not belong to user"
    end

    if wallet.account.balance_cents < amount_cents
      raise ArgumentError, "Insufficient funds"
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

      expense_account =
        Account.expense_account

      ledger_transaction =
        LedgerTransaction.create!(
          reference: SecureRandom.uuid,
          status: "completed",
          idempotency_key: idempotency_key,
          request_fingerprint: SecureRandom.uuid
        )

      Entry.create!(
        account: wallet.account,
        ledger_transaction: ledger_transaction,
        amount_cents: -amount_cents,
        entry_type: "credit"
      )

      Entry.create!(
        account: expense_account,
        ledger_transaction: ledger_transaction,
        amount_cents: amount_cents,
        entry_type: "debit"
      )

      wallet.account.update!(
        balance_cents:
          wallet.account.balance_cents - amount_cents
      )

      categorized_transaction =
      CategorizedTransaction.create!(
        user: user,
        category: category,
        ledger_transaction: ledger_transaction,
        transaction_type: "expense",
        note: note
      )

    categorized_transaction
    end
  end
end
