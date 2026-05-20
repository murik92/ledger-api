class ReconciliationJob
  include Sidekiq::Job

  def perform
    puts "Starting reconciliation..."

    verify_global_ledger_invariant

    Account.find_each do |account|
      verify_account_balance(account)
    end

    puts "Reconciliation completed"
  end

  private

  def verify_global_ledger_invariant
    total = Entry.sum(:amount_cents)

    if total.zero?
      puts "Global ledger invariant valid"
    else
      puts "LEDGER CORRUPTION DETECTED"
      puts "Total ledger sum: #{total}"
    end
  end

  def verify_account_balance(account)
    calculated_balance =
    account.entries.sum(:amount_cents)

    stored_balance =
      account.balance_cents

    if calculated_balance == stored_balance
      puts "Account #{account.id} balance verified"
    else
      puts "BALANCE MISMATCH DETECTED"
      puts "Account ID: #{account.id}"
      puts "Stored balance: #{stored_balance}"
      puts "Calculated balance: #{calculated_balance}"
    end
  end
end
