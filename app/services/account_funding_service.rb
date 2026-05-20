class AccountFundingService
  def self.call(account:, amount_cents:)
    system_account = Account.system_account

    ActiveRecord::Base.transaction do
      transaction = LedgerTransaction.create!(
        reference:
          "initial-funding-#{account.id}-#{SecureRandom.uuid}",
        status: "completed",
        idempotency_key:
          "initial-funding-key-#{SecureRandom.uuid}"
      )

      Entry.create!(
        account: system_account,
        ledger_transaction: transaction,
        amount_cents: -amount_cents,
        entry_type: "debit"
      )

      Entry.create!(
        account: account,
        ledger_transaction: transaction,
        amount_cents: amount_cents,
        entry_type: "credit"
      )

      account.update!(
        balance_cents: amount_cents,
        opening_balance_cents: amount_cents
      )
    end
  end
end
