require "rails_helper"

RSpec.describe RefreshToken, type: :model do
  let(:user) do
    User.create!(
      email: "#{SecureRandom.uuid}@example.com",
      password: "password123"
    )
  end

  describe "#expired?" do
    it "returns true when token expired" do
      token = RefreshToken.create!(
        user: user,
        token_digest: SecureRandom.hex,
        jti: SecureRandom.uuid,
        expires_at: 1.day.ago
      )

      expect(token.expired?).to be true
    end

    it "returns false when token is active" do
      token = RefreshToken.create!(
        user: user,
        token_digest: SecureRandom.hex,
        jti: SecureRandom.uuid,
        expires_at: 1.day.from_now
      )

      expect(token.expired?).to be false
    end
  end

  describe "#revoked?" do
    it "returns true when revoked_at exists" do
      token = RefreshToken.create!(
        user: user,
        token_digest: SecureRandom.hex,
        jti: SecureRandom.uuid,
        expires_at: 1.day.from_now,
        revoked_at: Time.current
      )

      expect(token.revoked?).to be true
    end
  end

  describe "#active?" do
    it "returns true for valid token" do
      token = RefreshToken.create!(
        user: user,
        token_digest: SecureRandom.hex,
        jti: SecureRandom.uuid,
        expires_at: 1.day.from_now
      )

      expect(token.active?).to be true
    end
  end

  describe "#revoke!" do
    it "sets revoked_at" do
      token = RefreshToken.create!(
        user: user,
        token_digest: SecureRandom.hex,
        jti: SecureRandom.uuid,
        expires_at: 1.day.from_now
      )

      token.revoke!

      expect(token.reload.revoked_at).to be_present
    end
  end
end
