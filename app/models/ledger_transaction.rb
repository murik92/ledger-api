class LedgerTransaction < ApplicationRecord
  has_many :entries,
           dependent: :restrict_with_exception

  has_one :categorized_transaction,
        dependent: :restrict_with_exception
        
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

  validates :request_fingerprint,
            presence: true
end
