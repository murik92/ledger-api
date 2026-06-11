require "swagger_helper"

RSpec.describe "Auth API", type: :request do
  path "/api/v1/login" do
    post "Login user" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"

      parameter name: :auth,
                in: :body,
                schema: {
                  type: :object,
                  properties: {
                    auth: {
                      type: :object,
                      properties: {
                        email: { type: :string },
                        password: { type: :string }
                      },
                      required: %w[email password]
                    }
                  }
                }

      let!(:user) do
        user = User.create!(
            email: "swagger#{SecureRandom.hex(4)}@example.com",
            password: "password123"
        )

        user.confirm!

        user
      end

      response "200", "login successful" do
        let(:auth) do
          {
            auth: {
              email: user.email,
              password: "password123"
            }
          }
        end

        run_test!
      end

      response "401", "invalid credentials" do
        let(:auth) do
          {
            auth: {
              email: "wrong@example.com",
              password: "wrong"
            }
          }
        end

        run_test!
      end
    end
  end
end
