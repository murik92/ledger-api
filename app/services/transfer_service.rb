class TransferService
  MAX_RETRIES = 3

  def self.call(from:, to:, amount_cents:, reference:)
    retries = 0

    begin
      existing_transaction = LedgerTransaction.find_by(reference: reference)

      return existing_transaction if existing_transaction

      ActiveRecord::Base.transaction(isolation: :serializable) do
        from.lock!
        to.lock!

        raise "Insufficient funds" if from.balance_cents < amount_cents

        transaction = LedgerTransaction.create!(
          reference: reference,
          status: "completed"
        )

        Entry.create!(
          account: from,
          ledger_transaction: transaction,
          amount_cents: -amount_cents,
          entry_type: "debit"
        )

        Entry.create!(
          account: to,
          ledger_transaction: transaction,
          amount_cents: amount_cents,
          entry_type: "credit"
        )

        from.update!(
          balance_cents: from.balance_cents - amount_cents
        )

        to.update!(
          balance_cents: to.balance_cents + amount_cents
        )
        
        AuditLog.create!(
        action: "transfer_created",
        entity_type: "LedgerTransaction",
        entity_id: transaction.id,
        metadata: {
          from_account_id: from.id,
          to_account_id: to.id,
          amount_cents: amount_cents,
          reference: reference
             }
            )
        transaction
      end

    rescue ActiveRecord::SerializationFailure
      retries += 1

      retry if retries < MAX_RETRIES

      raise "Transaction failed after retries"
    end
  end
end