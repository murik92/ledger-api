require "rails_helper"

RSpec.describe Wallet::SystemWalletService do
  describe ".create!" do
    it "creates a valid system wallet" do
      wallet =
        Wallet::SystemWalletService.create!(
          wallet_name: "treasury",
          currency: "USD"
        )

      expect(wallet.wallet_type)
        .to eq("system")

      expect(wallet.currency)
        .to eq("USD")

      expect(wallet.user)
        .to be_nil

      expect(wallet.account.name)
        .to eq("SYSTEM_TREASURY_USD")
    end

    it "rejects invalid system wallet types" do
      expect do
        Wallet::SystemWalletService.create!(
          wallet_name: "invalid_wallet",
          currency: "USD"
        )
      end.to raise_error(
        "Invalid system wallet type"
      )
    end

    it "returns existing system wallet for duplicates" do
        first_wallet =
            Wallet::SystemWalletService.create!(
            wallet_name: "treasury",
            currency: "USD"
            )

        second_wallet =
            Wallet::SystemWalletService.create!(
            wallet_name: "treasury",
            currency: "USD"
            )

        expect(first_wallet.id)
            .to eq(second_wallet.id)

        expect(Wallet.count).to eq(1)
    end
  end
end
