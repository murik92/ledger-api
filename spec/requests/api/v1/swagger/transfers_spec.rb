require "swagger_helper"

RSpec.describe "Transfers API", type: :request do
  let(:user) do
    User.create!(
      email: "swagger#{SecureRandom.hex(4)}@example.com",
      password: "password123"
    )
  end

  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:Authorization) { "Bearer #{token}" }

  let(:account) do
    Account.create!(user: user, name: "Main Account", currency: "USD", opening_balance_cents: 100_000, balance_cents: 100_000)
  end

  path "/api/v1/transfers" do
    post "Create transfer" do
      tags "Transfers"
      consumes "application/json"
      produces "application/json"

      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
            from_account_id: { type: :integer },
            to_account_id: { type: :integer },
            amount_cents: { type: :integer },
            idempotency_key: { type: :string }
        },
        required: %w[from_account_id to_account_id amount_cents idempotency_key]
        }

        let(:target_account) do
        Account.create!(
            user: user,
            name: "Target Account",
            currency: "USD",
            opening_balance_cents: 0,
            balance_cents: 0
        )
        end

        let(:payload) do
        {
            from_account_id: account.id,
            to_account_id: target_account.id,
            amount_cents: 1000,
            idempotency_key: SecureRandom.uuid
        }
        end

        response "201", "transfer successful" do
        run_test!
        end
    end
  end
end
