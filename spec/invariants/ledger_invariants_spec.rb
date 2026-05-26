require "rails_helper"

RSpec.describe "Ledger invariants" do
  def create_account(name:, balance:)
    account = Account.create!(
      name: name,
      currency: "USD",
      balance_cents: 0,
      opening_balance_cents: 0
    )

    AccountFundingService.call(
      account: account,
      amount_cents: balance
    )

    account.reload
  end

  describe "global balance invariant" do
    it "preserves total system balance" do
      from = create_account(
        name: "Alice",
        balance: 100_00
      )

      to = create_account(
        name: "Bob",
        balance: 50_00
      )

      total_before =
        Account.where.not(name: "SYSTEM")
               .sum(:balance_cents)

      TransferService.call(
        from: from,
        to: to,
        amount_cents: 25_00,
        reference: SecureRandom.uuid,
        idempotency_key: SecureRandom.uuid
      )

      total_after =
        Account.where.not(name: "SYSTEM")
               .sum(:balance_cents)

      expect(total_after).to eq(total_before)
    end
  end

  describe "account balance invariant" do
    it "matches account balance with entries sum" do
      account = create_account(
        name: "Charlie",
        balance: 200_00
      )

      entries_sum =
        account.entries.sum(:amount_cents)

      expect(account.balance_cents)
        .to eq(entries_sum)
    end
  end

  describe "no negative balances invariant" do
    it "prevents overdraft" do
      from = create_account(
        name: "David",
        balance: 100_00
      )

      to = create_account(
        name: "Eva",
        balance: 100_00
      )

      expect {
        TransferService.call(
          from: from,
          to: to,
          amount_cents: 500_00,
          reference: SecureRandom.uuid,
          idempotency_key: SecureRandom.uuid
        )
      }.to raise_error(StandardError)
    end
  end

  describe "transaction invariant" do
    it "keeps transaction entries balanced" do
      from = create_account(
        name: "Frank",
        balance: 300_00
      )

      to = create_account(
        name: "Grace",
        balance: 100_00
      )

      transaction = TransferService.call(
        from: from,
        to: to,
        amount_cents: 50_00,
        reference: SecureRandom.uuid,
        idempotency_key: SecureRandom.uuid
      )

      entries_sum =
        transaction.entries.sum(:amount_cents)

      expect(entries_sum).to eq(0)
    end
  end

  describe "idempotency invariant" do
    it "does not duplicate transaction" do
      from = create_account(
        name: "Henry",
        balance: 500_00
      )

      to = create_account(
        name: "Ivy",
        balance: 100_00
      )

      key = SecureRandom.uuid

      tx1 = TransferService.call(
        from: from,
        to: to,
        amount_cents: 100_00,
        reference: SecureRandom.uuid,
        idempotency_key: key
      )

      tx2 = TransferService.call(
        from: from,
        to: to,
        amount_cents: 100_00,
        reference: SecureRandom.uuid,
        idempotency_key: key
      )

      expect(tx1.id).to eq(tx2.id)

      expect(
        LedgerTransaction.where(
          idempotency_key: key
        ).count
      ).to eq(1)
    end
  end
end
