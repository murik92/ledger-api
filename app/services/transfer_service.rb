class TransferService
  MAX_RETRIES = 3

  def self.call(from:, to:, amount_cents:, reference:, idempotency_key:)
    retries = 0

    begin
      validate_transfer!(
        from: from,
        to: to,
        amount_cents: amount_cents
      )
      if idempotency_key.blank?
          raise BadRequestError,
        "Idempotency key is required"
      end

      existing_transaction =
        LedgerTransaction.find_by(
          idempotency_key: idempotency_key
        )

      return existing_transaction if existing_transaction

      ActiveRecord::Base.transaction(
        isolation: :serializable
      ) do
        from.lock!
          to.lock!

          if from.balance_cents < amount_cents
          raise StandardError, "Insufficient funds"
        end
        
        transaction = LedgerTransaction.create!(
          reference: reference,
          idempotency_key: idempotency_key,
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
          balance_cents:
            from.balance_cents - amount_cents
        )

        to.update!(
          balance_cents:
            to.balance_cents + amount_cents
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

    rescue ActiveRecord::RecordNotUnique
      LedgerTransaction.find_by!(
        idempotency_key: idempotency_key
      )
    end
  end

  def self.validate_transfer!(
    from:,
    to:,
    amount_cents:
  )
    if amount_cents <= 0
      raise "Amount must be greater than zero"
    end

    if from.id == to.id
      raise "Cannot transfer to the same account"
    end

    if from.currency != to.currency
      raise "Currency mismatch"
    end
  end
end
