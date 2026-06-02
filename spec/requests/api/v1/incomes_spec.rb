require "rails_helper"

RSpec.describe "Api::V1::Incomes", type: :request do
  before do
    CategorizedTransaction.delete_all
    Entry.delete_all
    LedgerTransaction.delete_all
    Category.delete_all
    Wallet.delete_all
    Account.delete_all
    User.delete_all
  end

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

  let(:category) do
    Category::CreateCategoryService.call(
      user: user,
      name: "Salary",
      category_type: "income"
    )
  end

  let(:token) do
    JsonWebToken.encode(
      user_id: user.id
    )
  end

  describe "POST /api/v1/incomes" do
    it "creates income transaction" do
      post "/api/v1/incomes",
      params: {
        wallet_id: wallet.id,
        category_id: category.id,
        amount_cents: 5000,
        note: "Monthly salary",
        idempotency_key: SecureRandom.uuid
      },
      headers: {
        "Authorization" => "Bearer #{token}"
      }

            
      expect(response).to have_http_status(:created)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(true)

      expect(
        CategorizedTransaction.count
      ).to eq(1)

      expect(
        wallet.account.reload.balance_cents
      ).to eq(5000)
    end
  end
end
