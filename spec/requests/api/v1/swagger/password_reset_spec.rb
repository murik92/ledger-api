require "swagger_helper"

RSpec.describe "Password Reset API", type: :request do
  path "/api/v1/auth/password_reset" do
    post "Request password reset" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"

      parameter name: :payload,
                in: :body,
                schema: {
                  type: :object,
                  properties: {
                    email: { type: :string }
                  },
                  required: %w[email]
                }

      let!(:user) do
        User.create!(
          email: "swagger#{SecureRandom.hex(4)}@example.com",
          password: "password123"
        )
      end

      response "200", "password reset token generated" do
        let(:payload) do
          {
            email: user.email
          }
        end

        run_test!
      end

      response "422", "unknown email" do
        let(:payload) do
          {
            email: "unknown@example.com"
          }
        end

        run_test!
      end
    end
  end

  path "/api/v1/auth/reset_password" do
    post "Reset password" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"

      parameter name: :payload,
                in: :body,
                schema: {
                  type: :object,
                  properties: {
                    token: { type: :string },
                    password: { type: :string },
                    password_confirmation: { type: :string }
                  },
                  required: %w[token password password_confirmation]
                }

      let!(:user) do
        user = User.create!(
          email: "swagger#{SecureRandom.hex(4)}@example.com",
          password: "oldpassword123"
        )

        user.generate_password_reset_token
        user
      end

      response "200", "password updated" do
        let(:payload) do
          {
            token: user.reset_password_token,
            password: "newpassword123",
            password_confirmation: "newpassword123"
          }
        end

        run_test!
      end

      response "422", "invalid reset token" do
        let(:payload) do
          {
            token: "invalid-token",
            password: "newpassword123",
            password_confirmation: "newpassword123"
          }
        end

        run_test!
      end
    end
  end
end
