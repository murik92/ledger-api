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

   def generate_password_reset_token
     update!(
       reset_password_token: SecureRandom.urlsafe_base64(32),
       reset_password_sent_at: Time.current
      )
    end

    def clear_password_reset_token
      update!(
       reset_password_token: nil,
       reset_password_sent_at: nil
      )
    end

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

   def password_reset_token_expired?
     return true if reset_password_sent_at.nil?

     reset_password_sent_at < 15.minutes.ago
   end

end
