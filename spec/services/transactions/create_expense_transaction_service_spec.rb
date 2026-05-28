require "rails_helper"

RSpec.describe Transactions::CreateExpenseTransactionService do
  let(:user) do
    User.create!(
      email: "#{SecureRandom.uuid}@example.com",
      password: "password123"
    )
  end

  let(:expense_category) do
    Category.create!(
      user: user,
      name: "Food",
      category_type: "expense"
    )
  end

  let(:income_category) do
    Category.create!(
      user: user,
      name: "Salary",
      category_type: "income"
    )
  end

  describe ".call" do
    it "creates expense categorized transaction" do
      result = described_class.call(
        user: user,
        category: expense_category,
        note: "Dinner"
      )

      expect(result).to be_persisted

      expect(result.transaction_type)
        .to eq("expense")

      expect(result.note)
        .to eq("Dinner")

      expect(result.category)
        .to eq(expense_category)

      expect(result.user)
        .to eq(user)
    end

    it "creates ledger transaction" do
      result = described_class.call(
        user: user,
        category: expense_category,
        note: "Dinner"
      )

      expect(
        result.ledger_transaction
      ).to be_present
    end

    it "rejects income category" do
      expect do
        described_class.call(
          user: user,
          category: income_category,
          note: "Invalid"
        )
      end.to raise_error(
        ArgumentError,
        "Category must be expense type"
      )
    end
  end
end
