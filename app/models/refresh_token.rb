class RefreshToken < ApplicationRecord
  belongs_to :user

  validates :token_digest,
            presence: true,
            uniqueness: true

  validates :jti,
            presence: true,
            uniqueness: true

  validates :expires_at,
            presence: true

  def expired?
    expires_at <= Time.current
  end

  def revoked?
    revoked_at.present?
  end

  def active?
    !expired? && !revoked?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end
end
