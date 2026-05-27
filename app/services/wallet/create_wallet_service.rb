class Wallet::CreateWalletService
  def self.call(
    user:,
    currency:,
    name:
  )
    ActiveRecord::Base.transaction do
      existing_wallet =
        Wallet.find_by(
          user: user,
          currency: currency,
          wallet_type: "user"
        )

      if existing_wallet
        raise(
          "User already has #{currency} wallet"
        )
      end

      account = Account.create!(
        user: user,
        name: "#{name} Account",
        currency: currency,
        balance_cents: 0,
        opening_balance_cents: 0
      )

      Wallet.create!(
        user: user,
        account: account,
        currency: currency,
        status: "active",
        wallet_type: "user",
        name: name
      )
    end
  end
end
