require "rails_helper"

RSpec.describe CategorizedTransaction, type: :model do
  let(:user) do
    User.create!(
      email: "#{SecureRandom.uuid}@example.com",
      password: "password123"
    )
  end

  let(:another_user) do
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

  let(:ledger_transaction) do
    LedgerTransaction.create!(
      reference: SecureRandom.uuid,
      status: "completed",
      idempotency_key: SecureRandom.uuid,
      request_fingerprint: SecureRandom.uuid
    )
  end

  describe "scopes" do
  it "returns expense transactions" do
    expense = CategorizedTransaction.create!(
      user: user,
      category: expense_category,
      ledger_transaction: ledger_transaction,
      transaction_type: "expense",
      note: "Food"
    )

    income = CategorizedTransaction.create!(
      user: user,
      category: income_category,
      ledger_transaction: LedgerTransaction.create!(
        reference: SecureRandom.uuid,
        status: "completed",
        idempotency_key: SecureRandom.uuid,
        request_fingerprint: SecureRandom.uuid
      ),
      transaction_type: "income",
      note: "Salary"
    )

    expect(
      CategorizedTransaction.expenses
    ).to include(expense)

    expect(
      CategorizedTransaction.expenses
    ).not_to include(income)
    end

    it "returns income transactions" do
      income = CategorizedTransaction.create!(
        user: user,
        category: income_category,
        ledger_transaction: ledger_transaction,
        transaction_type: "income",
        note: "Salary"
      )

      expect(
        CategorizedTransaction.income
      ).to include(income)
    end
  end

  describe "associations" do
    it "belongs to user" do
      categorized_transaction =
        CategorizedTransaction.new(
          user: user,
          ledger_transaction: ledger_transaction,
          category: expense_category,
          transaction_type: "expense"
        )

      expect(
        categorized_transaction.user
      ).to eq(user)
    end
  end

  describe "validations" do
    it "is valid with valid attributes" do
      categorized_transaction =
        CategorizedTransaction.new(
          user: user,
          ledger_transaction: ledger_transaction,
          category: expense_category,
          transaction_type: "expense"
        )

      expect(
        categorized_transaction
      ).to be_valid
    end

    it "requires matching category type" do
      categorized_transaction =
        CategorizedTransaction.new(
          user: user,
          ledger_transaction: ledger_transaction,
          category: income_category,
          transaction_type: "expense"
        )

      expect(
        categorized_transaction
      ).not_to be_valid

      expect(
        categorized_transaction.errors[:category]
      ).to include(
        "type must match transaction type"
      )
    end

    it "requires category ownership" do
      чужая_категория = Category.create!(
        user: another_user,
        name: "Foreign",
        category_type: "expense"
      )

      categorized_transaction =
        CategorizedTransaction.new(
          user: user,
          ledger_transaction: ledger_transaction,
          category: чужая_категория,
          transaction_type: "expense"
        )

      expect(
        categorized_transaction
      ).not_to be_valid

      expect(
        categorized_transaction.errors[:category]
      ).to include(
        "must belong to transaction user"
      )
    end
  end

  describe "helpers" do
    it "supports expense transactions" do
      categorized_transaction =
        CategorizedTransaction.new(
          transaction_type: "expense"
        )

      expect(
        categorized_transaction.expense?
      ).to eq(true)
    end

    it "supports income transactions" do
      categorized_transaction =
        CategorizedTransaction.new(
          transaction_type: "income"
        )

      expect(
        categorized_transaction.income?
      ).to eq(true)
    end
  end
end
