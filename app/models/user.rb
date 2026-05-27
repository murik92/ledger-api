class User < ApplicationRecord
  has_secure_password

  has_many :wallets,
           dependent: :restrict_with_exception

  has_many :accounts,
           dependent: :restrict_with_exception

  has_many :categories,
           dependent: :restrict_with_exception

  validates :email,
            presence: true,
            uniqueness: true
end
