class LedgerTransaction < ApplicationRecord
  has_many :entries

  validates :reference, presence: true, uniqueness: true
  validates :status, presence: true
end