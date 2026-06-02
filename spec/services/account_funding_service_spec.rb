require "rails_helper"

RSpec.describe AccountFundingService do
  let(:account) do
    Account.create!(
      name: "Funding Test",
      currency: "USD",
      balance_cents: 0,
      opening_balance_cents: 0
    )
  end

  describe ".call" do
    it "does not execute funding twice with same idempotency key" do
      key = "funding-key-001"

      described_class.call(
        account: account,
        amount_cents: 10_000,
        idempotency_key: key
      )

      described_class.call(
        account: account,
        amount_cents: 10_000,
        idempotency_key: key
      )

      account.reload

      expect(account.balance_cents)
        .to eq(10_000)

      expect(
        LedgerTransaction.where(
          idempotency_key: key
        ).count
      ).to eq(1)
    end
  end
end
