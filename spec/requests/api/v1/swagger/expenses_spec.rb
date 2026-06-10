require "swagger_helper"

RSpec.describe "Expenses API", type: :request do
  let(:user) { User.create!(email: "swagger#{SecureRandom.hex(4)}@example.com", password: "password123") }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:Authorization) { "Bearer #{token}" }

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

  let(:category) do
    Category.create!(user: user, name: "Food", category_type: "expense")
  end

  path "/api/v1/expenses" do
    post "Create expense" do
      tags "Expenses"
      consumes "application/json"
      produces "application/json"

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          wallet_id: { type: :integer },
          category_id: { type: :integer },
          amount_cents: { type: :integer },
          note: { type: :string },
          idempotency_key: { type: :string }
        },
        required: %w[wallet_id category_id amount_cents idempotency_key]
      }

      let(:payload) do
        {
          wallet_id: wallet.id,
          category_id: category.id,
          amount_cents: 1000,
          note: "Lunch",
          idempotency_key: SecureRandom.uuid
        }
      end

      response "201", "expense created" do
        run_test!
      end
    end
  end
end
