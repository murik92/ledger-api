require "rails_helper"

RSpec.describe "Password Reset", type: :request do
  describe "POST /api/v1/auth/password_reset" do
    let!(:user) do
      User.create!(
        email: "#{SecureRandom.uuid}@example.com",
        password: "password123"
      )
    end

    it "generates password reset token" do
      post "/api/v1/auth/password_reset",
           params: {
             email: user.email
           }

      expect(response).to have_http_status(:ok)

      user.reload

      expect(user.reset_password_token).to be_present
      expect(user.reset_password_sent_at).to be_present
    end

    it "returns error for unknown email" do
      post "/api/v1/auth/password_reset",
           params: {
             email: "unknown@example.com"
           }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /api/v1/auth/reset_password" do
        let!(:user) do
            User.create!(
            email: "#{SecureRandom.uuid}@example.com",
            password: "oldpassword123"
            )
        end

        it "resets password" do
            user.generate_password_reset_token

            post "/api/v1/auth/reset_password",
                params: {
                token: user.reset_password_token,
                password: "newpassword123",
                password_confirmation: "newpassword123"
                }

            expect(response).to have_http_status(:ok)

            user.reload

            expect(
            user.authenticate("newpassword123")
            ).to be_truthy

            expect(
            user.reset_password_token
            ).to be_nil
        end

        it "returns error for invalid token" do
            post "/api/v1/auth/reset_password",
                params: {
                token: "invalid-token",
                password: "newpassword123",
                password_confirmation: "newpassword123"
                }

            expect(response).to have_http_status(
            :unprocessable_content
            )
        end

        it "returns error when reset token expired" do
            user = User.create!(
                email: "#{SecureRandom.uuid}@example.com",
                password: "password123",
                reset_password_token: SecureRandom.hex(16),
                reset_password_sent_at: 20.minutes.ago
            )

            post "/api/v1/auth/reset_password",
                params: {
                    token: user.reset_password_token,
                    password: "newpassword123",
                    password_confirmation: "newpassword123"
                }

            expect(response).to have_http_status(
                :unprocessable_content
            )

            body = JSON.parse(response.body)

            expect(body["message"]).to eq(
                "Reset token expired"
            )
        end
    end
end
