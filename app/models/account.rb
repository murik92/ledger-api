class Account < ApplicationRecord
  has_many :entries

  validates :name, presence: true

  validates :currency, presence: true

  validates :opening_balance_cents,
            numericality: {
              greater_than_or_equal_to: 0
            }

  validates :balance_cents,
            numericality: {
              greater_than_or_equal_to: 0
            }
end