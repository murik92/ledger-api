require 'rails_helper'

RSpec.describe "Api::V1::Transfers", type: :request do

  before(:each) do
    Entry.delete_all
    LedgerTransaction.delete_all
    AuditLog.delete_all
    Account.delete_all
  end

  let!(:alice) do
    Account.create!(
      name: "Alice",
      currency: "USD",
      balance_cents: 100_000,
      opening_balance_cents: 100_000
    )
  end

  let!(:bob) do
    Account.create!(
      name: "Bob",
      currency: "USD",
      balance_cents: 50_000,
      opening_balance_cents: 50_000
    )
  end

  describe "POST /api/v1/transfers" do

    it "creates transfer successfully" do
      post "/api/v1/transfers",
      params: {
        from_account_id: alice.id,
        to_account_id: bob.id,
        amount_cents: 10_000,
        reference: "api-transfer-001"
      },
      headers: {
        "Idempotency-Key" => "api-key-001"
      }

      puts response.body

      expect(response).to have_http_status(:created)

      body = JSON.parse(response.body)

      expect(body["status"]).to eq("success")

      expect(alice.reload.balance_cents).to eq(90_000)
      expect(bob.reload.balance_cents).to eq(60_000)
    end

    it "returns error without idempotency key" do
      post "/api/v1/transfers",
      params: {
        from_account_id: alice.id,
        to_account_id: bob.id,
        amount_cents: 10_000,
        reference: "api-transfer-002"
      }

      expect(response).to have_http_status(:bad_request)

      body = JSON.parse(response.body)

      expect(body["error"]).to eq(
        "Idempotency-Key header required"
      )
    end

    it "returns not found for invalid account" do
      post "/api/v1/transfers",
      params: {
        from_account_id: 999999,
        to_account_id: bob.id,
        amount_cents: 10_000,
        reference: "api-transfer-003"
      },
      headers: {
        "Idempotency-Key" => "api-key-003"
      }

      expect(response).to have_http_status(:not_found)

      body = JSON.parse(response.body)

      expect(body["error"]).to eq(
        "Account not found"
      )
    end
  end
end
