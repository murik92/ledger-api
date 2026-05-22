class ReconciliationService
  def self.call
    puts "Starting reconciliation..."

    validate_global_invariant!

    Account.find_each do |account|
      validate_account!(account)
    end

    puts "Reconciliation completed"
  end

  def self.validate_global_invariant!
    total =
      Entry.sum(:amount_cents)

    if total != 0
      raise(
        "Global ledger invariant violated: #{total}"
      )
    end

    puts "Global ledger invariant valid"
  end

  def self.validate_account!(account)
    calculated_balance =
      account.entries.sum(:amount_cents)

    if calculated_balance != account.balance_cents
      raise(
        "Account #{account.id} mismatch: " \
        "expected #{calculated_balance}, " \
        "actual #{account.balance_cents}"
      )
    end

    puts "Account #{account.id} balance verified"
  end
end
