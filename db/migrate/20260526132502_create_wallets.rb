class CreateWallets < ActiveRecord::Migration[7.1]
  def change
    create_table :wallets do |t|
      t.references :user,
                   foreign_key: true,
                   null: true

      t.references :account,
                   foreign_key: true,
                   null: false

      t.string :currency,
               null: false

      t.string :status,
               null: false,
               default: "active"

      t.string :wallet_type,
               null: false,
               default: "user"

      t.string :name,
               null: false

      t.timestamps
    end

    add_index :wallets,
              [:user_id, :currency],
              unique: true,
              where: "wallet_type = 'user'",
              name: "index_user_wallets_on_currency_unique"

    add_check_constraint(
      :wallets,
      "status IN ('active', 'frozen', 'archived')",
      name: "wallets_valid_status"
    )

    add_check_constraint(
      :wallets,
      "wallet_type IN ('user', 'system')",
      name: "wallets_valid_type"
    )
  end
end
