require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  describe "#confirmation_email" do
    let(:user) do
      User.create!(
        email: "confirm_#{SecureRandom.hex(4)}@example.com",
        password: "password123",
        password_confirmation: "password123",
        confirmation_token: SecureRandom.hex(16)
      )
    end

    subject(:mail) do
      UserMailer.confirmation_email(user)
    end

    it "sends to correct recipient" do
      expect(mail.to).to eq(
        [user.email]
      )
    end

    it "has correct subject" do
      expect(mail.subject).to eq(
        "Confirm your email"
      )
    end

    it "contains confirmation token" do
      expect(mail.body.encoded).to include(
         user.confirmation_token
      )
    end
  end

  describe "#password_reset_email" do
    let(:user) do
      User.create!(
        email: "reset_#{SecureRandom.hex(4)}@example.com",
        password: "password123",
        password_confirmation: "password123",
        reset_password_token: SecureRandom.hex(16)
      )
    end

    subject(:mail) do
      UserMailer.password_reset_email(user)
    end

    it "sends to correct recipient" do
      expect(mail.to).to eq(
         [user.email]
      )
    end

    it "has correct subject" do
      expect(mail.subject).to eq(
        "Reset your password"
      )
    end

    it "contains reset token" do
      expect(mail.body.encoded).to include(
        user.reset_password_token
      )
    end
  end
end
