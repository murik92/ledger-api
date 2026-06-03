require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  describe "POST /api/v1/login" do
    let!(:user) do
      User.create!(
        email: "#{SecureRandom.uuid}@example.com",
        password: "password123"
      )
    end

    it "logs in user" do
      post "/api/v1/login",
           params: {
             auth: {
               email: user.email,
               password: "password123"
             }
           }

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)

      expect(body["status"]).to eq("success")

      expect(
        body["data"]["tokens"]["access_token"]
      ).to be_present

      expect(
        body["data"]["tokens"]["refresh_token"]
      ).to be_present
    end
  end
end
