class AddSystemWalletUniquenessConstraint < ActiveRecord::Migration[7.1]
  def change
    add_index :wallets,
              [:name, :currency],
              unique: true,
              where: "wallet_type = 'system'",
              name: "index_system_wallets_unique"
  end
end
