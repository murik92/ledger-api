require 'rails_helper'

RSpec.describe TransferService do

  before(:each) do
    Entry.delete_all
    LedgerTransaction.delete_all
    AuditLog.delete_all
    Account.delete_all
  end

  def create_account_with_balance(
    name:,
    currency:,
    balance_cents:
  )
    account = Account.create!(
      name: name,
      currency: currency,
      balance_cents: balance_cents
    )

    transaction = LedgerTransaction.create!(
      reference: "initial-balance-#{name}",
      status: "completed",
      idempotency_key: "initial-key-#{name}"
    )

    Entry.create!(
      account: account,
      ledger_transaction: transaction,
      amount_cents: balance_cents,
      entry_type: "credit"
    )

    account
  end

  describe '.call' do

    let!(:alice) do
      create_account_with_balance(
        name: "Alice",
        currency: "USD",
        balance_cents: 100_000
      )
    end

    let!(:bob) do
      create_account_with_balance(
        name: "Bob",
        currency: "USD",
        balance_cents: 50_000
      )
    end

    it 'transfers money between accounts' do
      TransferService.call(
        from: alice,
        to: bob,
        amount_cents: 10_000,
        reference: "spec-transfer-001",
        idempotency_key: "spec-key-001"
      )

      expect(alice.reload.balance_cents).to eq(90_000)
      expect(bob.reload.balance_cents).to eq(60_000)

      expect(LedgerTransaction.count).to eq(3)
      expect(Entry.count).to eq(4)
    end

    it 'raises error when balance is insufficient' do
      expect {
        TransferService.call(
          from: alice,
          to: bob,
          amount_cents: 999_999,
          reference: "spec-transfer-002",
          idempotency_key: "spec-key-002"
        )
      }.to raise_error("Insufficient funds")

      expect(alice.reload.balance_cents).to eq(100_000)
      expect(bob.reload.balance_cents).to eq(50_000)

      expect(LedgerTransaction.count).to eq(2)
      expect(Entry.count).to eq(2)
    end

    it 'does not create duplicate transfer with same idempotency key' do
      expect {

        TransferService.call(
          from: alice,
          to: bob,
          amount_cents: 10_000,
          reference: "duplicate-transfer-001",
          idempotency_key: "duplicate-key-001"
        )

        TransferService.call(
          from: alice,
          to: bob,
          amount_cents: 10_000,
          reference: "duplicate-transfer-001",
          idempotency_key: "duplicate-key-001"
        )

      }.to change(LedgerTransaction, :count).by(1)
       .and change(Entry, :count).by(2)

      expect(alice.reload.balance_cents).to eq(90_000)
      expect(bob.reload.balance_cents).to eq(60_000)
    end
  end
end