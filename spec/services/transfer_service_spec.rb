require 'rails_helper'

RSpec.describe TransferService do
  describe '.call' do
    let!(:alice) do
      Account.create!(
        name: "Alice",
        currency: "USD",
        balance_cents: 100_000
      )
    end

    let!(:bob) do
      Account.create!(
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
        reference: "spec-transfer-001"
      )

      expect(alice.reload.balance_cents).to eq(90_000)
      expect(bob.reload.balance_cents).to eq(60_000)

      expect(LedgerTransaction.count).to eq(1)
      expect(Entry.count).to eq(2)
    end

    it 'raises error when balance is insufficient' do
        expect {
        expect {
        TransferService.call(
        from: alice,
        to: bob,
        amount_cents: 999_999,
        reference: "spec-transfer-002"
        )
        }.to raise_error("Insufficient funds")
        }.to change(LedgerTransaction, :count).by(0)
        .and change(Entry, :count).by(0)

        expect(alice.reload.balance_cents).to eq(100_000)
        expect(bob.reload.balance_cents).to eq(50_000)
    end
    it 'does not create duplicate transfer with same reference' do
            expect {
            TransferService.call(
              from: alice,
               to: bob,
                 amount_cents: 10_000,
                 reference: "duplicate-transfer-001"
                )

             TransferService.call(
            from: alice,
            to: bob,
            amount_cents: 10_000,
            reference: "duplicate-transfer-001"
             )

             }.to change(LedgerTransaction, :count).by(1)
             .and change(Entry, :count).by(2)

            expect(alice.reload.balance_cents).to eq(90_000)
             expect(bob.reload.balance_cents).to eq(60_000)
        end
    end
end