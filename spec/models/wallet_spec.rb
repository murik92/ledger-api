require "rails_helper"

RSpec.describe Wallet, type: :model do
  let(:user) do
    User.create!(
      email: "#{SecureRandom.uuid}@example.com",
      password: "password123"
    )
  end

  let(:account) do
    Account.create!(
      name: "Primary Account",
      balance_cents: 0,
      opening_balance_cents: 0,
      currency: "USD",
      user: user
    )
  end

  describe "associations" do
    it "belongs to user optionally" do
      wallet = Wallet.new(
        account: account,
        currency: "USD",
        name: "Main Wallet"
      )

      expect(wallet.user).to be_nil
    end

    it "belongs to account" do
      wallet = Wallet.new(
        user: user,
        account: account,
        currency: "USD",
        name: "Main Wallet"
      )

      expect(wallet.account).to eq(account)
    end
  end

  describe "validations" do
    it "is valid with valid attributes" do
      wallet = Wallet.new(
        user: user,
        account: account,
        currency: "USD",
        name: "Main Wallet",
        status: "active",
        wallet_type: "user"
      )

      expect(wallet).to be_valid
    end

    it "requires user for user wallet" do
      wallet = Wallet.new(
        account: account,
        currency: "USD",
        name: "Main Wallet",
        wallet_type: "user"
      )

      expect(wallet).not_to be_valid

      expect(wallet.errors[:user])
        .to include("must exist for user wallets")
    end

    it "forbids user for system wallet" do
      wallet = Wallet.new(
        user: user,
        account: account,
        currency: "USD",
        name: "Treasury",
        wallet_type: "system"
      )

      expect(wallet).not_to be_valid

      expect(wallet.errors[:user])
        .to include("must be absent for system wallets")
    end

    it "requires matching account currency" do
      eur_account = Account.create!(
        name: "EUR Account",
        balance_cents: 0,
        opening_balance_cents: 0,
        currency: "EUR",
        user: user
      )

      wallet = Wallet.new(
        user: user,
        account: eur_account,
        currency: "USD",
        name: "Broken Wallet"
      )

      expect(wallet).not_to be_valid

      expect(wallet.errors[:currency])
        .to include("must match account currency")
    end
  end

  describe "policy methods" do
    it "allows active wallet to send" do
      wallet = Wallet.new(
        user: user,
        account: account,
        currency: "USD",
        name: "Main Wallet",
        status: "active"
      )

      expect(wallet.can_send?).to eq(true)
    end

    it "prevents frozen wallet from sending" do
      wallet = Wallet.new(
        user: user,
        account: account,
        currency: "USD",
        name: "Frozen Wallet",
        status: "frozen"
      )

      expect(wallet.can_send?).to eq(false)
    end

    it "makes archived wallet immutable" do
      wallet = Wallet.new(
        user: user,
        account: account,
        currency: "USD",
        name: "Archived Wallet",
        status: "archived"
      )

      expect(wallet.mutable?).to eq(false)
    end
  end
  
  describe "archived wallet immutability" do
  it "prevents archived wallet updates" do
    wallet = Wallet.create!(
      user: user,
      account: account,
      currency: "USD",
      name: "Archived Wallet",
      status: "archived",
      wallet_type: "user"
    )

    result = wallet.update(
      name: "Changed Name"
    )

    expect(result).to eq(false)

    expect(wallet.errors[:base])
      .to include(
        "Archived wallets are immutable"
      )
    end
    end
end
