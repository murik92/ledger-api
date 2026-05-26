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
    system = Account.system_account

    account = Account.create!(
      name: name,
      currency: currency,
      balance_cents: balance_cents,
      opening_balance_cents: balance_cents
    )

    transaction = LedgerTransaction.create!(
      reference:
        "initial-balance-#{name}-#{SecureRandom.uuid}",
      status: "completed",
      idempotency_key:
        "initial-key-#{name}-#{SecureRandom.uuid}",
      request_fingerprint:
        SecureRandom.hex
    ) 

    Entry.create!(
      account: system,
      ledger_transaction: transaction,
      amount_cents: -balance_cents,
      entry_type: "debit"
    )

    Entry.create!(
      account: account,
      ledger_transaction: transaction,
      amount_cents: balance_cents,
      entry_type: "credit"
    )

    system.update!(
      balance_cents:
        system.balance_cents - balance_cents
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
      expect(Entry.count).to eq(6)
    end

    it 'raises error when balance is insufficient' do
      expect do
        TransferService.call(
          from: alice,
          to: bob,
          amount_cents: 999_999,
          reference: "spec-transfer-002",
          idempotency_key: "spec-key-002"
        )
      end.to raise_error("Insufficient funds")

      expect(alice.reload.balance_cents).to eq(100_000)
      expect(bob.reload.balance_cents).to eq(50_000)

      expect(LedgerTransaction.count).to eq(2)
      expect(Entry.count).to eq(4)
    end

    it 'does not create duplicate transfer with same idempotency key' do
      expect do

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

      end.to change(LedgerTransaction, :count).by(1)
         .and change(Entry, :count).by(2)

      expect(alice.reload.balance_cents).to eq(90_000)
      expect(bob.reload.balance_cents).to eq(60_000)
    end

    it 'handles concurrent transfers safely' do
      threads = []

      10.times do |i|
        threads << Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            begin
              TransferService.call(
                from: alice,
                to: bob,
                amount_cents: 10_000,
                reference: "concurrent-transfer-#{i}",
                idempotency_key: "concurrent-key-#{i}"
              )
            rescue => e
              puts e.message
            end
          end
        end
      end

      threads.each(&:join)

      alice.reload
      bob.reload

      expect(alice.balance_cents).to be >= 0

      total_balance =
        alice.balance_cents +
        bob.balance_cents

      expect(total_balance).to eq(150_000)

      total_entries_sum =
        Entry.sum(:amount_cents)

      expect(total_entries_sum).to eq(0)
    end
  end
end

