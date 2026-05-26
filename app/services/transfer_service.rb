class TransferService
  MAX_RETRIES = 3

  def self.call(from:, to:, amount_cents:, reference:, idempotency_key:)
    retries = 0

    begin
      fingerprint_payload = {
        from_account_id: from.id,
        to_account_id: to.id,
        amount_cents: amount_cents
      }

      request_fingerprint =
        Digest::SHA256.hexdigest(
          fingerprint_payload.to_json
        )

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

      if existing_transaction
        if existing_transaction.request_fingerprint != request_fingerprint
          raise StandardError,
                "Idempotency key reuse with different payload"
        end

        return existing_transaction
      end

      ActiveRecord::Base.transaction(
        isolation: :serializable
      ) do
        accounts = [from, to].sort_by(&:id)

        accounts.each(&:lock!)

        if from.balance_cents < amount_cents
          raise StandardError,
                "Insufficient funds"
        end

        transaction = LedgerTransaction.create!(
          reference: reference,
          idempotency_key: idempotency_key,
          request_fingerprint: request_fingerprint,
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

      if retries < MAX_RETRIES
        backoff_time =
          (0.05 * (2 ** retries)) +
          rand(0.0..0.05)

        sleep(backoff_time)

        retry
      end

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
