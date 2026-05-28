require "rails_helper"

RSpec.describe Transactions::CreateIncomeTransactionService do
  let(:user) do
    User.create!(
      email: "#{SecureRandom.uuid}@example.com",
      password: "password123"
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
        category: income_category,
        note: "Monthly salary"
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
        category: income_category,
        note: "Monthly salary"
      )

      expect(
        result.ledger_transaction
      ).to be_present
    end

    it "rejects expense category" do
      expect do
        described_class.call(
          user: user,
          category: expense_category,
          note: "Invalid"
        )
      end.to raise_error(
        ArgumentError,
        "Category must be income type"
      )
    end
  end
end
