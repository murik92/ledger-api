class AccountFundingService
  MAX_RETRIES = 3

  def self.call(account:, amount_cents:)
    retries = 0

    begin
      system_account = Account.system_account

      ActiveRecord::Base.transaction(
        isolation: :serializable
      ) do
        accounts =
          [system_account, account]
          .sort_by(&:id)

        accounts.each(&:lock!)

        transaction = LedgerTransaction.create!(
          reference:
            "initial-funding-#{account.id}-#{SecureRandom.uuid}",
          status: "completed",
          idempotency_key:
            "initial-funding-key-#{SecureRandom.uuid}",
          request_fingerprint:
            SecureRandom.uuid
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
          balance_cents:
            account.balance_cents + amount_cents,
          opening_balance_cents:
            account.opening_balance_cents + amount_cents
        )
      end

    rescue ActiveRecord::SerializationFailure
      retries += 1

      if retries < MAX_RETRIES
        backoff_time =
          (0.05 * (2 ** retries)) + rand(0.0..0.05)

        sleep(backoff_time)

        retry
      end

      raise "Funding failed after retries"
    end
  end
end
