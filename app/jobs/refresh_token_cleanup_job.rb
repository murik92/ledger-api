# app/jobs/refresh_token_cleanup_job.rb
class RefreshTokenCleanupJob < ApplicationJob
  queue_as :default

  # Запускается ежедневно (например через sidekiq-cron)
  def perform
    expired_tokens = RefreshToken.where("expires_at <= ?", Time.current)
    deleted_count = expired_tokens.delete_all
    Rails.logger.info("[RefreshTokenCleanupJob] Deleted #{deleted_count} expired refresh tokens")
  end
end
