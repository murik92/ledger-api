require "rails_helper"

RSpec.describe "Randomized Ledger Simulation" do
  def create_account(balance)
    account = Account.create!(
      name: SecureRandom.uuid,
      currency: "USD",
      balance_cents: 0,
      opening_balance_cents: 0
    )

    AccountFundingService.call(
      account: account,
      amount_cents: balance,
      idempotency_key: SecureRandom.uuid
    )

    account.reload
  end

  def verify_invariants(accounts, initial_total)
    total =
      Account.where.not(name: "SYSTEM")
             .sum(:balance_cents)

    expect(total)
      .to eq(initial_total)

    accounts.each do |account|
      account.reload

      expect(account.balance_cents)
        .to be >= 0

      expect(account.balance_cents)
        .to eq(
          account.entries.sum(:amount_cents)
        )
    end

    LedgerTransaction.find_each do |transaction|
      expect(
        transaction.entries.sum(:amount_cents)
      ).to eq(0)
    end
  end

  it "preserves ledger invariants after every random transfer" do
    accounts = Array.new(5) do
      create_account(100_00)
    end

    initial_total =
      Account.where.not(name: "SYSTEM")
             .sum(:balance_cents)

    100.times do
      from, to = accounts.sample(2)

      amount =
        rand(1..20_00)

      begin
        TransferService.call(
          from: from,
          to: to,
          amount_cents: amount,
          reference: SecureRandom.uuid,
          idempotency_key: SecureRandom.uuid
        )
      rescue StandardError
      end

      verify_invariants(
        accounts,
        initial_total
      )
    end
  end
end
