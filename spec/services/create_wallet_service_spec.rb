require "rails_helper"

RSpec.describe Wallet::CreateWalletService do
  before(:each) do
    Category.delete_all
    Wallet.delete_all
    Entry.delete_all
    LedgerTransaction.delete_all
    AuditLog.delete_all
    Account.delete_all
    User.delete_all
  end

  let(:user) do
    User.create!(
      email: "#{SecureRandom.uuid}@example.com",
      password: "password123"
    )
  end

  describe ".call" do
    it "creates wallet and account" do
      wallet =
        Wallet::CreateWalletService.call(
          user: user,
          currency: "USD",
          name: "Main Wallet"
        )

      expect(wallet).to be_persisted

      expect(wallet.currency).to eq("USD")
      expect(wallet.wallet_type).to eq("user")

      expect(wallet.account).to be_present

      expect(wallet.account.currency)
        .to eq("USD")
    end

    it "prevents duplicate wallets per currency" do
      Wallet::CreateWalletService.call(
        user: user,
        currency: "USD",
        name: "Main Wallet"
      )

      expect do
        Wallet::CreateWalletService.call(
          user: user,
          currency: "USD",
          name: "Second Wallet"
        )
      end.to raise_error(
        "User already has USD wallet"
      )

      expect(Wallet.count).to eq(1)
    end

    it "rolls back account creation on failure" do
      allow(Wallet).to receive(:create!)
        .and_raise(StandardError.new("Wallet failure"))

      expect do
        Wallet::CreateWalletService.call(
          user: user,
          currency: "USD",
          name: "Broken Wallet"
        )
      end.to raise_error("Wallet failure")

      expect(Account.count).to eq(0)
      expect(Wallet.count).to eq(0)
    end
  end
end
