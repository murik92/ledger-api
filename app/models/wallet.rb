class Wallet < ApplicationRecord
  belongs_to :user,
             optional: true

  belongs_to :account

  enum status: {
    active: "active",
    frozen: "frozen",
    archived: "archived"
  }, _prefix: true

  enum wallet_type: {
    user: "user",
    system: "system"
  }, _prefix: true

  validates :currency,
            presence: true

  validates :name,
            presence: true

  validates :status,
            presence: true

  validates :wallet_type,
            presence: true

  validates :account_id,
            uniqueness: true

  validate :validate_user_wallet_ownership
  validate :validate_system_wallet_rules
  validate :validate_currency_matches_account

  validate :validate_archived_wallet_immutability,
         on: :update

  validate :validate_status_transition,
         on: :update

  def can_send?
    status_active?
  end

  def can_receive?
    status_active?
  end

  def mutable?
    !status_archived?
  end

  private

def validate_archived_wallet_immutability
  return unless status_archived? || status_was == "archived"

  immutable_fields = [
    "status",
    "currency",
    "wallet_type",
    "user_id",
    "account_id",
    "name"
  ]

  changed_immutable_fields =
    changes.keys & immutable_fields

  return unless changed_immutable_fields.any?

  errors.add(
    :base,
    "Archived wallets are immutable"
  )
end

    def validate_status_transition
    return unless will_save_change_to_status?

    allowed_transitions = {
        "active" => %w[frozen archived],
        "frozen" => %w[active archived],
        "archived" => []
    }

    previous_status = status_was
    new_status = status

    allowed_statuses =
        allowed_transitions[previous_status] || []

    return if allowed_statuses.include?(new_status)

    errors.add(
        :status,
        "invalid status transition"
    )
    end

  def validate_user_wallet_ownership
    return unless wallet_type_user?

    if user_id.nil?
      errors.add(
        :user,
        "must exist for user wallets"
      )
    end
  end

  def validate_system_wallet_rules
    return unless wallet_type_system?

    if user_id.present?
      errors.add(
        :user,
        "must be absent for system wallets"
      )
    end
  end

  def validate_currency_matches_account
    return if account.nil?

    if currency != account.currency
      errors.add(
        :currency,
        "must match account currency"
      )
    end
  end
end
