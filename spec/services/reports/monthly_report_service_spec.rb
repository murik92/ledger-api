require "rails_helper"

RSpec.describe Reports::MonthlyReportService do
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

  before do
    Transactions::CreateIncomeTransactionService.call(
      user: user,
      wallet: wallet,
      category: income_category,
      amount_cents: 10_000,
      note: "Salary",
      idempotency_key: SecureRandom.uuid
    )

    Transactions::CreateExpenseTransactionService.call(
      user: user,
      wallet: wallet,
      category: expense_category,
      amount_cents: 3_000,
      note: "Food",
      idempotency_key: SecureRandom.uuid
    )
  end

  describe ".call" do
    it "returns monthly report statistics" do
      report =
        described_class.call(
          user: user,
          month: Date.current.strftime("%Y-%m")
        )

      expect(
        report[:income_transactions]
      ).to eq(1)

      expect(
        report[:expense_transactions]
      ).to eq(1)

      expect(
        report[:income_cents]
      ).to eq(10_000)

      expect(
        report[:expense_cents]
      ).to eq(3_000)

      expect(
        report[:net_cashflow_cents]
      ).to eq(7_000)
    end
  end
end
