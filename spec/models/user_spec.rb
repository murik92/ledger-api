require "rails_helper"

RSpec.describe User, type: :model do
  it "creates valid user" do
    user = User.create!(
      email: "#{SecureRandom.uuid}@example.com",
      password: "password123"
    )

    expect(user).to be_persisted
  end

  it "returns false when user is not confirmed" do
    user = User.create!(
      email: "#{SecureRandom.uuid}@example.com",
      password: "password123"
    )

    expect(user.confirmed?).to be(false)
  end

  it "returns true when user is confirmed" do
    user = User.create!(
      email: "#{SecureRandom.uuid}@example.com",
      password: "password123",
      confirmed_at: Time.current
    )

    expect(user.confirmed?).to be(true)
  end

  it "generates confirmation token" do
    user = User.create!(
      email: "#{SecureRandom.uuid}@example.com",
      password: "password123"
    )

    user.generate_confirmation_token

    expect(user.confirmation_token).to be_present
    expect(user.confirmation_sent_at).to be_present
  end

  it "confirms user" do
    user = User.create!(
      email: "#{SecureRandom.uuid}@example.com",
      password: "password123"
    )

    user.generate_confirmation_token
    user.confirm!

    expect(user.confirmed_at).to be_present
    expect(user.confirmation_token).to be_nil
    expect(user.confirmed?).to be(true)
  end
end
