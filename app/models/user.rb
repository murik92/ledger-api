require "securerandom"

class User < ApplicationRecord
  has_secure_password

  has_many :refresh_tokens,
         dependent: :destroy
         
  has_many :categorized_transactions,
         dependent: :restrict_with_exception
         
  has_many :wallets,
           dependent: :restrict_with_exception

  has_many :accounts,
           dependent: :restrict_with_exception

  has_many :categories,
           dependent: :restrict_with_exception

  validates :email,
            presence: true,
            uniqueness: true

   def confirmed?
     confirmed_at.present?
   end

   def generate_confirmation_token
     update!(
       confirmation_token: SecureRandom.urlsafe_base64(32),
       confirmation_sent_at: Time.current
     )
   end

   def confirm!
     update!(
       confirmed_at: Time.current,
       confirmation_token: nil
     )
   end
end
