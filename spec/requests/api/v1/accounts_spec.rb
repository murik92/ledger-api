require "rails_helper"

RSpec.describe "Api::V1::Accounts", type: :request do
  let!(:user) do
    User.create!(
      email: "accounts@example.com",
      password: "password123"
    )
  end

  let(:token) do
    JsonWebToken.encode(
      user_id: user.id
    )
  end

  it "returns accounts list" do
    get "/api/v1/accounts",
        headers: {
          "Authorization" => "Bearer #{token}"
        }

    expect(response).to have_http_status(:ok)

    body = JSON.parse(response.body)

    expect(body["status"]).to eq("success")
  end
end
