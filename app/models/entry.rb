class Entry < ApplicationRecord
  belongs_to :account
  belongs_to :ledger_transaction

  validates :amount_cents, presence: true
  validates :entry_type, presence: true
end