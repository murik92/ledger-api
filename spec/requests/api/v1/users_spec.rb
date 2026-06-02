require "rails_helper"

RSpec.describe "Api::V1::Users", type: :request do
  describe "POST /api/v1/register" do
    it "registers user" do
      post "/api/v1/register",
           params: {
             user: {
               email: "user@example.com",
               password: "password123",
               password_confirmation: "password123"
             }
           }

      expect(response).to have_http_status(:created)

      body = JSON.parse(response.body)

      expect(body["status"]).to eq("success")
      expect(body["token"]).to be_present
    end
  end
end
