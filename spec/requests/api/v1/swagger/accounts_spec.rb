require "swagger_helper"

RSpec.describe "Accounts API", type: :request do
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

  path "/api/v1/accounts" do
    get "List accounts" do
      tags "Accounts"
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true

      response "200", "returns user accounts" do
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        run_test!
      end
    end

    post "Create account" do
      tags "Accounts"
      consumes "application/json"
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          account: {
            type: :object,
            properties: {
              name: { type: :string },
              currency: { type: :string }
            },
            required: %w[name currency]
          }
        },
        required: %w[account]
      }

      response "201", "account created" do
        let(:payload) { { account: { name: "Savings", currency: "USD" } } }
        run_test!
      end
    end
  end

  path "/api/v1/accounts/{id}/deposit" do
    post "Deposit to account" do
      tags "Accounts"
      consumes "application/json"
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          amount_cents: { type: :integer }
        },
        required: ["amount_cents"]
      }

      let(:id) { account.id }
      let(:payload) { { amount_cents: 5000 } }

      response "200", "deposit successful" do
        run_test!
      end
    end
  end

  path "/api/v1/accounts/{id}/withdraw" do
    post "Withdraw from account" do
      tags "Accounts"
      consumes "application/json"
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          amount_cents: { type: :integer }
        },
        required: ["amount_cents"]
      }

      let(:id) { account.id }
      let(:payload) { { amount_cents: 3000 } }

      response "200", "withdraw successful" do
        run_test!
      end
    end
  end

  path "/api/v1/accounts/{id}" do
    get "Show account" do
      tags "Accounts"
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer, required: true

      let(:id) { account.id }

      response "200", "returns account details" do
        run_test!
      end
    end
  end
end
