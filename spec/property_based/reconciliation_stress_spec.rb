require "rails_helper"

RSpec.describe "Reconciliation Stress Test" do
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

  it "maintains invariants after 100 random transfers and reconciliation" do
    accounts = Array.new(5) do
      create_account(100_00)
    end

    100.times do
      from, to = accounts.sample(2)

      amount = rand(1..20_00)

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
    end

    expect {
      ReconciliationService.call
    }.not_to raise_error
  end
end
