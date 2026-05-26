class Account < ApplicationRecord
  
  belongs_to :user, optional: true

  has_many :entries,
         dependent: :restrict_with_exception

  validates :name, presence: true

  validates :currency, presence: true

  validates :opening_balance_cents,
            numericality: {
              greater_than_or_equal_to: 0
            }

  validates :balance_cents,
            numericality: true,
            unless: :system_account?

  def system_account?
    name == "SYSTEM"
  end

  def self.system_account
    find_or_create_by!(
      name: "SYSTEM",
      currency: "USD"
    ) do |account|
      account.balance_cents = 0
      account.opening_balance_cents = 0
    end
  end
end

