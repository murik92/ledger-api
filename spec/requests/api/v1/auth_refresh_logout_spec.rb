require "rails_helper"

RSpec.describe "Auth Refresh & Logout API", type: :request do
  let!(:user) do
    User.create!(
        email: "#{SecureRandom.uuid}@example.com",
        password: "password123"
    )
    end

  describe "POST /api/v1/auth/refresh" do
    it "rotates refresh token and returns new access token" do
      tokens = Auth::TokenIssuer.issue_tokens_for(user)
      old_refresh = tokens[:refresh_token]

      post "/api/v1/auth/refresh", params: { refresh_token: old_refresh }
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["data"]["access_token"]).to be_present
      expect(json["data"]["refresh_token"]).not_to eq(old_refresh)
    end

    it "rejects expired or revoked token" do
      tokens = Auth::TokenIssuer.issue_tokens_for(user)
      refresh_token = tokens[:refresh_token]

      # revoke token вручную
      digest = Digest::SHA256.hexdigest(refresh_token)
      RefreshToken.find_by(token_digest: digest).revoke!

      post "/api/v1/auth/refresh", params: { refresh_token: refresh_token }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/auth/logout" do
    it "revokes refresh token" do
        tokens = Auth::TokenIssuer.issue_tokens_for(user)

        refresh_token = tokens[:refresh_token]
        access_token  = tokens[:access_token]

        post "/api/v1/auth/logout",
            params: {
            refresh_token: refresh_token
            },
            headers: {
            "Authorization" => "Bearer #{access_token}"
            }

        expect(response).to have_http_status(:ok)

        digest = Digest::SHA256.hexdigest(refresh_token)

        record = RefreshToken.find_by(
        token_digest: digest
        )

        expect(record.revoked?).to be true
    end
  end
end
