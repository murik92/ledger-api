require "rails_helper"

RSpec.describe User, type: :model do
  it "creates valid user" do
    user = User.create!(
      email: "#{SecureRandom.uuid}@example.com",
      password: "password123"
    )

    expect(user).to be_persisted
  end
end
