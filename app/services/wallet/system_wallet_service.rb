class Wallet::SystemWalletService
  SYSTEM_WALLET_TYPES = %w[
    treasury
    fees
    settlement
    liquidity
    fx_rounding
  ].freeze

  def self.create!(
    wallet_name:,
    currency:
    )
    validate_wallet_name!(wallet_name)

    existing_wallet =
        Wallet.find_by(
        name: wallet_name.to_s,
        currency: currency,
        wallet_type: "system"
        )

    return existing_wallet if existing_wallet

    account = Account.create!(
        name: "SYSTEM_#{wallet_name.upcase}_#{currency}",
        currency: currency,
        balance_cents: 0,
        opening_balance_cents: 0
    )

    Wallet.create!(
        account: account,
        currency: currency,
        status: "active",
        wallet_type: "system",
        name: wallet_name.to_s
    )
    end

  def self.validate_wallet_name!(wallet_name)
    unless SYSTEM_WALLET_TYPES.include?(
      wallet_name.to_s
    )
      raise(
        "Invalid system wallet type"
      )
    end
  end
end
