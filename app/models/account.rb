class Account < ApplicationRecord
  has_many :entries

  validates :name, presence: true
  validates :currency, presence: true
end