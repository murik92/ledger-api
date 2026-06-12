require "swagger_helper"

RSpec.describe "Auth Confirm API", type: :request do
  path "/api/v1/auth/confirm" do
    post "Confirm user email" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"

      parameter name: :payload,
                in: :body,
                schema: {
                  type: :object,
                  properties: {
                    token: { type: :string }
                  },
                  required: %w[token]
                }

      let!(:user) do
        user = User.create!(
          email: "swagger#{SecureRandom.hex(4)}@example.com",
          password: "password123"
        )

        user.generate_confirmation_token
        user
      end

      response "200", "email confirmed" do
        let(:payload) do
          {
            token: user.confirmation_token
          }
        end

        run_test!
      end

      response "422", "confirmation token missing" do
        let(:payload) do
          {
            token: nil
          }
        end

        run_test!
      end

      response "422", "invalid confirmation token" do
        let(:payload) do
          {
            token: "invalid-token"
          }
        end

        run_test!
      end
    end
  end
end
