require "rails_helper"

RSpec.describe "Create Transaction API", type: :request do
  before do
    CategorizedTransaction.delete_all
    Category.delete_all
    Wallet.delete_all
    Entry.delete_all
    LedgerTransaction.delete_all
    Account.delete_all
    RefreshToken.delete_all
    User.delete_all
  end

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

  let(:account) do
    Account.create!(
      user: user,
      name: "Main Account",
      currency: "USD",
      opening_balance_cents: 100_000,
      balance_cents: 100_000
    )
  end

  let(:wallet) do
    Wallet.create!(
        user: user,
        account: account,
        name: "Main Wallet",
        currency: "USD"
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

  describe "POST /api/v1/transactions" do
    it "creates expense transaction" do
      post "/api/v1/transactions",
           params: {
             transaction_type: "expense",
             wallet_id: wallet.id,
             category_id: expense_category.id,
             amount_cents: 1000,
             note: "Lunch",
             idempotency_key: SecureRandom.uuid
           },
           headers: headers

      expect(response)
        .to have_http_status(:created)

      expect(CategorizedTransaction.count)
        .to eq(1)
    end

    it "creates income transaction" do
      post "/api/v1/transactions",
           params: {
             transaction_type: "income",
             wallet_id: wallet.id,
             category_id: income_category.id,
             amount_cents: 5000,
             note: "Salary",
             idempotency_key: SecureRandom.uuid
           },
           headers: headers

      expect(response)
        .to have_http_status(:created)

      expect(CategorizedTransaction.count)
        .to eq(1)
    end

    it "rejects invalid transaction type" do
      post "/api/v1/transactions",
           params: {
             transaction_type: "invalid",
             wallet_id: wallet.id,
             category_id: income_category.id,
             amount_cents: 5000,
             note: "Salary",
             idempotency_key: SecureRandom.uuid
           },
           headers: headers

      expect(response)
        .to have_http_status(:unprocessable_content)
    end
  end
end
