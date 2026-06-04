# spec/requests/api/v1/auth_confirm_spec.rb
require "rails_helper"

RSpec.describe "Api::V1::Auth Confirmation", type: :request do
  describe "POST /api/v1/auth/confirm" do
    let!(:user) do
      User.create!(
        email: "#{SecureRandom.uuid}@example.com",
        password: "password123"
      )
    end

    before do
      user.generate_confirmation_token
    end

    it "confirms user email with valid token" do
      post "/api/v1/auth/confirm", params: { token: user.confirmation_token }

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["status"]).to eq("success")
      expect(body["message"]).to eq("Email confirmed successfully")

      # Проверяем, что токен сброшен и confirmed_at установлен
      user.reload
      expect(user.confirmed?).to be true
      expect(user.confirmation_token).to be_nil
    end

    it "returns error when token is missing" do
      post "/api/v1/auth/confirm", params: { token: nil }

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("error")
      expect(body["message"]).to eq("Confirmation token missing")
    end

    it "returns error when token is invalid" do
      post "/api/v1/auth/confirm", params: { token: "invalidtoken123" }

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("error")
      expect(body["message"]).to eq("Invalid confirmation token")
    end

    it "does not allow using the same token twice" do
      # Первый вызов успешный
      post "/api/v1/auth/confirm", params: { token: user.confirmation_token }
      expect(response).to have_http_status(:ok)

      # Второй вызов с тем же токеном
      post "/api/v1/auth/confirm", params: { token: user.confirmation_token }
      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("error")
      expect(body["message"]).to eq("Invalid confirmation token")
    end
  end
end
