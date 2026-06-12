require "swagger_helper"

RSpec.describe "Auth Register API", type: :request do
  path "/api/v1/register" do
    post "Register user" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"

      parameter name: :payload,
                in: :body,
                schema: {
                  type: :object,
                  properties: {
                    user: {
                      type: :object,
                      properties: {
                        email: { type: :string },
                        password: { type: :string },
                        password_confirmation: { type: :string }
                      },
                      required: %w[email password password_confirmation]
                    }
                  },
                  required: %w[user]
                }

      response "201", "user registered" do
        let(:payload) do
          {
            user: {
              email: "swagger#{SecureRandom.hex(4)}@example.com",
              password: "password123",
              password_confirmation: "password123"
            }
          }
        end

        run_test!
      end

      response "422", "invalid registration data" do
        let(:payload) do
          {
            user: {
              email: "",
              password: "",
              password_confirmation: ""
            }
          }
        end

        run_test!
      end
    end
  end
end
