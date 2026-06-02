require "rails_helper"

RSpec.describe Transactions::CreateIncomeTransactionService do
  let(:user) do
    User.create!(
      email: "#{SecureRandom.uuid}@example.com",
      password: "password123"
    )
  end

  let(:wallet) do
    Wallet::CreateWalletService.call(
      user: user,
      currency: "USD",
      name: "Main wallet"
    )
  end

  let(:income_category) do
    Category.create!(
      user: user,
      name: "Salary",
      category_type: "income"
    )
  end

  let(:expense_category) do
    Category.create!(
      user: user,
      name: "Food",
      category_type: "expense"
    )
  end

  describe ".call" do
    it "creates income categorized transaction" do
      result = described_class.call(
        user: user,
        wallet: wallet,
        category: income_category,
        amount_cents: 5_000,
        note: "Monthly salary",
        idempotency_key: SecureRandom.uuid
      )

      expect(result).to be_persisted

      expect(result.transaction_type)
        .to eq("income")

      expect(result.note)
        .to eq("Monthly salary")

      expect(result.category)
        .to eq(income_category)

      expect(result.user)
        .to eq(user)
    end

    it "creates ledger transaction" do
      result = described_class.call(
        user: user,
        wallet: wallet,
        category: income_category,
        amount_cents: 5_000,
        note: "Monthly salary",
        idempotency_key: SecureRandom.uuid
      )

      expect(
        result.ledger_transaction
      ).to be_present
    end

    it "rejects expense category" do
      expect do
        described_class.call(
          user: user,
          wallet: wallet,
          category: expense_category,
          amount_cents: 5_000,
          note: "Invalid",
          idempotency_key: SecureRandom.uuid
        )
      end.to raise_error(
        ArgumentError,
        "Category must be income type"
      )
    end

    it "does not create duplicate income with same idempotency key" do
      key = "income-key-001"

      described_class.call(
        user: user,
        wallet: wallet,
        category: income_category,
        amount_cents: 5_000,
        note: "Salary",
        idempotency_key: key
      )

      described_class.call(
        user: user,
        wallet: wallet,
        category: income_category,
        amount_cents: 5_000,
        note: "Salary",
        idempotency_key: key
      )

      wallet.reload
      
      account =
        Account.find(wallet.account_id)
          expect(
        LedgerTransaction.where(
          idempotency_key: key
        ).count
      ).to eq(1)

      expect(
        account.balance_cents
      ).to eq(5_000)
    end
  end
end
