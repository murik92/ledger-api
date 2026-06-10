require "swagger_helper"

RSpec.describe "Incomes API", type: :request do
  let(:user) { User.create!(email: "swagger#{SecureRandom.hex(4)}@example.com", password: "password123") }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:Authorization) { "Bearer #{token}" }

  let(:account) do
    Account.create!(user: user, name: "Main Account", currency: "USD", opening_balance_cents: 100_000, balance_cents: 100_000)
  end

  let(:wallet) do
    Wallet.create!(user: user, account: account, name: "Main Wallet", currency: "USD")
  end

  let(:income_category) do
    Category.create!(user: user, name: "Salary", category_type: "income")
  end

  path "/api/v1/incomes" do
    post "Create income" do
      tags "Incomes"
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

      response "201", "income created" do
        let(:payload) do
          {
            wallet_id: wallet.id,
            category_id: income_category.id,
            amount_cents: 5000,
            note: "Salary",
            idempotency_key: SecureRandom.uuid
          }
        end

        run_test!
      end
    end
  end
end
