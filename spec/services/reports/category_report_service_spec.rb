require "rails_helper"

RSpec.describe Reports::CategoryReportService do
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

  let(:salary_category) do
    Category.create!(
      user: user,
      name: "Salary",
      category_type: "income"
    )
  end

  let(:bonus_category) do
    Category.create!(
      user: user,
      name: "Bonus",
      category_type: "income"
    )
  end

  before do
    Transactions::CreateIncomeTransactionService.call(
      user: user,
      wallet: wallet,
      category: salary_category,
      amount_cents: 10_000,
      note: "Salary",
      idempotency_key: SecureRandom.uuid
    )

    Transactions::CreateIncomeTransactionService.call(
      user: user,
      wallet: wallet,
      category: bonus_category,
      amount_cents: 3_000,
      note: "Bonus",
      idempotency_key: SecureRandom.uuid
    )
  end

  describe ".call" do
    it "groups transactions by category" do
      report =
        described_class.call(
          user: user,
          from: Date.current.beginning_of_month,
          to: Date.current.end_of_month,
          transaction_type: "income"
        )

      expect(report.size)
        .to eq(2)

      expect(
        report.map { |r| r[:category] }
      ).to contain_exactly(
        "Salary",
        "Bonus"
      )

      expect(
        report.find { |r| r[:category] == "Salary" }[:amount_cents]
      ).to eq(10_000)

      expect(
        report.find { |r| r[:category] == "Bonus" }[:amount_cents]
      ).to eq(3_000)
    end
  end
end
