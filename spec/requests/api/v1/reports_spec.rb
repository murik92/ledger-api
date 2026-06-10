require "rails_helper"

RSpec.describe "Reports API", type: :request do
  let(:user) do
    User.create!(
      email: "#{SecureRandom.uuid}@example.com",
      password: "password123"
    )
  end

  let(:token) do
    JsonWebToken.encode(
        user_id: user.id
    )
  end

  let(:headers) do
    {
      "Authorization" => "Bearer #{token}"
    }
  end

  let(:wallet) do
    Wallet::CreateWalletService.call(
      user: user,
      currency: "USD",
      name: "Main Wallet"
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

  describe "GET /api/v1/reports/monthly" do
    it "returns monthly report" do
      get(
        "/api/v1/reports/monthly",
        headers: headers
      )

      expect(response).to have_http_status(:ok)

      json =
        JSON.parse(response.body)

      expect(json["status"])
        .to eq("success")

      expect(json["data"])
        .to have_key("income_cents")

      expect(json["data"])
        .to have_key("expense_cents")

      expect(json["data"])
        .to have_key("net_cashflow_cents")
    end
  end

  describe "GET /api/v1/reports/cashflow" do
    it "returns cashflow report" do
      get(
        "/api/v1/reports/cashflow",
        headers: headers
      )

      expect(response).to have_http_status(:ok)

      json =
        JSON.parse(response.body)

      expect(json["status"])
        .to eq("success")

      expect(json["data"])
        .to have_key("income_cents")

      expect(json["data"])
        .to have_key("expense_cents")

      expect(json["data"])
        .to have_key("net_cashflow_cents")
    end
  end

  describe "GET /api/v1/reports/by_category" do
    it "returns category report" do
      get(
        "/api/v1/reports/by_category",
        params: {
          transaction_type: "expense"
        },
        headers: headers
      )

      expect(response).to have_http_status(:ok)

      json =
        JSON.parse(response.body)

      expect(json["status"])
        .to eq("success")

      expect(json["data"])
        .to be_an(Array)
    end
  end
end
