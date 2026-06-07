require "rails_helper"

RSpec.describe "Rate Limiting", type: :request do
  describe "Auth rate limit" do
    it "blocks after 5 requests per minute" do
      5.times do
        post "/api/v1/login",
             params: {
               auth: {
                 email: "unknown@example.com",
                 password: "password123"
               }
             }
      end

      post "/api/v1/login",
           params: {
             auth: {
               email: "unknown@example.com",
               password: "password123"
             }
           }

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "Write endpoint rate limit" do
    it "blocks after 60 write requests per minute" do
      user = User.create!(
        email: "#{SecureRandom.uuid}@example.com",
        password: "password123",
        confirmed_at: Time.current
      )

      token = JsonWebToken.issue_access_token(user)

      60.times do
        post "/api/v1/accounts",
             params: {
               account: {
                 name: SecureRandom.hex(4)
               }
             },
             headers: {
               "Authorization" => "Bearer #{token}"
             }
      end

      post "/api/v1/accounts",
           params: {
             account: {
               name: "blocked_account"
             }
           },
           headers: {
             "Authorization" => "Bearer #{token}"
           }

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "Transfers rate limit" do
    it "blocks after 10 transfer requests per minute" do
      sender = User.create!(
        email: "#{SecureRandom.uuid}@example.com",
        password: "password123",
        confirmed_at: Time.current
      )

      receiver = User.create!(
        email: "#{SecureRandom.uuid}@example.com",
        password: "password123",
        confirmed_at: Time.current
      )

      sender_account = Account.create!(
        user: sender,
        name: "Sender",
        currency: "USD",
        balance_cents: 10_000,
        opening_balance_cents: 10_000
      )

      receiver_account = Account.create!(
        user: receiver,
        name: "Receiver",
        currency: "USD",
        balance_cents: 0,
        opening_balance_cents: 0
      )

      token = JsonWebToken.issue_access_token(sender)

      10.times do
        post "/api/v1/transfers",
             params: {
               from_account_id: sender_account.id,
               to_account_id: receiver_account.id,
               amount: 1
             },
             headers: {
               "Authorization" => "Bearer #{token}"
             }
      end

      post "/api/v1/transfers",
           params: {
             from_account_id: sender_account.id,
             to_account_id: receiver_account.id,
             amount: 1
           },
           headers: {
             "Authorization" => "Bearer #{token}"
           }

      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
