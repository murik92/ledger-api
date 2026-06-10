require "swagger_helper"

RSpec.describe "Reports API", type: :request do
  let(:user) do
    User.create!(
      email: "swagger#{SecureRandom.hex(4)}@example.com",
      password: "password123"
    )
  end

  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:Authorization) { "Bearer #{token}" }

  let(:wallet) do
    Wallet::CreateWalletService.call(user: user, currency: "USD", name: "Main Wallet")
  end

  let(:income_category) do
    Category.create!(user: user, name: "Salary", category_type: "income")
  end

  let(:expense_category) do
    Category.create!(user: user, name: "Food", category_type: "expense")
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

  path "/api/v1/reports/monthly" do
    get "Monthly report" do
      tags "Reports"
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true

      response "200", "returns monthly report" do
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        run_test!
      end
    end
  end

  path "/api/v1/reports/cashflow" do
    get "Cashflow report" do
      tags "Reports"
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true

      response "200", "returns cashflow report" do
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        run_test!
      end
    end
  end

  path "/api/v1/reports/by_category" do
    get "Category report" do
      tags "Reports"
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :transaction_type,
          in: :query,
          type: :string,
          required: false,
          enum: %w[income expense]

      response "200", "returns category report" do
        let(:transaction_type) { "expense" }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        let(:transaction_type) { "expense" }
        run_test!
      end
    end
  end
end
