require "swagger_helper"

RSpec.describe "Auth API - Refresh & Logout", type: :request do
  let!(:user) do
    User.create!(
      email: "swagger#{SecureRandom.hex(4)}@example.com",
      password: "password123"
    )
  end

  let!(:tokens) { Auth::TokenIssuer.issue_tokens_for(user) }
  let(:raw_refresh_token) { tokens[:refresh_token] }
  let(:access_token) { tokens[:access_token] }

  path "/api/v1/auth/refresh" do
    post "Refresh access token" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"

      parameter name: :payload,
                in: :body,
                schema: {
                  type: :object,
                  properties: {
                    refresh_token: { type: :string }
                  },
                  required: ["refresh_token"]
                }

      response "200", "token refreshed" do
        let(:payload) do
          {
            refresh_token: raw_refresh_token
          }
        end

        run_test!
      end

      response "401", "invalid token" do
        let(:payload) do
          {
            refresh_token: "invalidtoken"
          }
        end

        run_test!
      end
    end
  end

  path "/api/v1/auth/logout" do
    post "Logout user" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"

      parameter name: :Authorization,
                in: :header,
                type: :string,
                required: true,
                description: "Bearer access token"

      parameter name: :payload,
                in: :body,
                schema: {
                  type: :object,
                  properties: {
                    refresh_token: { type: :string }
                  },
                  required: ["refresh_token"]
                }

      response "200", "logout successful" do
        let(:Authorization) { "Bearer #{access_token}" }
        let(:payload) do
          {
            refresh_token: raw_refresh_token
          }
        end

        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalidtoken" }
        let(:payload) do
          {
            refresh_token: raw_refresh_token
          }
        end

        run_test!
      end
    end
  end
end
