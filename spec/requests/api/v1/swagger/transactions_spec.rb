require "swagger_helper"

RSpec.describe "Transactions API", type: :request do
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
      email: "swagger#{SecureRandom.hex(4)}@example.com",
      password: "password123"
    )
  end

  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:Authorization) { "Bearer #{token}" }

  let!(:expense_category) do
    Category.create!(user: user, name: "Food", category_type: "expense")
  end

  let!(:income_category) do
    Category.create!(user: user, name: "Salary", category_type: "income")
  end

  let(:account) do
    Account.create!(user: user, name: "Main Account", currency: "USD", opening_balance_cents: 100_000, balance_cents: 100_000)
  end

  let(:wallet) do
    Wallet.create!(user: user, account: account, name: "Main Wallet", currency: "USD")
  end

  path "/api/v1/transactions" do
    get "List transactions" do
      tags "Transactions"
      produces "application/json"

      parameter name: :Authorization, in: :header, type: :string, required: true

      response "200", "returns all user transactions" do
        before do
          LedgerTransaction.create!(reference: SecureRandom.uuid, status: "completed", idempotency_key: SecureRandom.uuid, request_fingerprint: SecureRandom.uuid).tap do |tx|
            CategorizedTransaction.create!(user: user, ledger_transaction: tx, category: expense_category, transaction_type: "expense", note: "Lunch")
          end

          LedgerTransaction.create!(reference: SecureRandom.uuid, status: "completed", idempotency_key: SecureRandom.uuid, request_fingerprint: SecureRandom.uuid).tap do |tx|
            CategorizedTransaction.create!(user: user, ledger_transaction: tx, category: income_category, transaction_type: "income", note: "Salary")
          end
        end

        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        run_test!
      end
    end

    post "Create transaction" do
      tags "Transactions"
      consumes "application/json"
      produces "application/json"

      parameter name: :Authorization, in: :header, type: :string, required: true

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          transaction_type: { type: :string, enum: %w[income expense] },
          wallet_id: { type: :integer },
          category_id: { type: :integer },
          amount_cents: { type: :integer },
          note: { type: :string },
          idempotency_key: { type: :string }
        },
        required: %w[transaction_type wallet_id category_id amount_cents idempotency_key]
      }

      response "201", "transaction created" do
        let(:payload) do
          {
            transaction_type: "expense",
            wallet_id: wallet.id,
            category_id: expense_category.id,
            amount_cents: 1000,
            note: "Lunch",
            idempotency_key: SecureRandom.uuid
          }
        end

        run_test!
      end

      response "422", "invalid transaction type" do
        let(:payload) do
          {
            transaction_type: "invalid",
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

  path "/api/v1/transactions/{id}" do
    parameter name: :id, in: :path, type: :integer, required: true
    let!(:transaction_record) do
        ledger_transaction =
            LedgerTransaction.create!(
            reference: SecureRandom.uuid,
            status: "completed",
            idempotency_key: SecureRandom.uuid,
            request_fingerprint: SecureRandom.uuid
            )

        CategorizedTransaction.create!(
            user: user,
            ledger_transaction: ledger_transaction,
            category: expense_category,
            transaction_type: "expense",
            note: "Lunch"
        )
        end
    let(:id) { transaction_record.id }

    get "Retrieve transaction" do
      tags "Transactions"
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true

      response "200", "transaction details" do
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        run_test!
      end
    end
  end
end
