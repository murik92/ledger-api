class LedgerTransaction < ApplicationRecord
  has_many :entries,
           dependent: :destroy

  enum status: {
    pending: "pending",
    completed: "completed",
    failed: "failed"
  }

  validates :reference,
            presence: true,
            uniqueness: true

  validates :status,
            presence: true

  validates :idempotency_key,
            presence: true,
            uniqueness: true
end
