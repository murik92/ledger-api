require "rails_helper"

RSpec.describe "Categories API", type: :request do
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

  describe "GET /api/v1/categories" do
    it "returns user categories" do
      Category.create!(
        user: user,
        name: "Food",
        category_type: "expense"
      )

      Category.create!(
        user: user,
        name: "Salary",
        category_type: "income"
      )

      get "/api/v1/categories",
          headers: headers

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)

      expect(body["status"])
        .to eq("success")

      expect(body["data"].size)
        .to eq(2)
    end

    it "returns unauthorized without token" do
      get "/api/v1/categories"

      expect(response)
        .to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/categories" do
    it "creates category" do
      post "/api/v1/categories",
           params: {
             category: {
               name: "Food",
               category_type: "expense"
             }
           },
           headers: headers

      expect(response)
        .to have_http_status(:created)

      expect(Category.count)
        .to eq(1)
    end

    it "rejects duplicate categories" do
      Category.create!(
        user: user,
        name: "Food",
        category_type: "expense"
      )

      post "/api/v1/categories",
           params: {
             category: {
               name: "Food",
               category_type: "expense"
             }
           },
           headers: headers

      expect(response)
        .to have_http_status(:unprocessable_content)
    end
  end
end
