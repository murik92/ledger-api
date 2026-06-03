# app/services/auth/token_issuer.rb
module Auth
  class TokenIssuer
    # Генерация пары токенов для пользователя
    #
    # Возвращает Hash:
    # {
    #   access_token: "...",
    #   refresh_token: "...", # plain, для клиента
    #   expires_in: 600
    # }
    def self.issue_tokens_for(user)
      # --- Access Token ---
      access_token = JsonWebToken.issue_access_token(user, ttl: 10.minutes)

      # --- Refresh Token ---
      plain_refresh, token_digest, payload, expires_at = JsonWebToken.issue_refresh_token(user)

      # Сохраняем в БД
      user.refresh_tokens.create!(
        token_digest: token_digest,
        jti: payload[:jti],
        expires_at: expires_at
      )

      {
        access_token: access_token,
        refresh_token: plain_refresh,
        token_type: "Bearer",
        expires_in: 10.minutes.to_i
      }
    end

    # --- Rotation для refresh token ---
    # Старый refresh token помечается revoked
    # Новый создаётся и сохраняется
    def self.rotate_refresh_token(user, old_token)
      old_digest = Digest::SHA256.hexdigest(old_token)
      token_record = user.refresh_tokens.find_by(token_digest: old_digest)

      raise ActiveRecord::RecordNotFound, "Refresh token not found" if token_record.nil?
      raise StandardError, "Refresh token revoked or expired" unless token_record.active?

      # Отзываем старый
      token_record.revoke!

      # Генерируем новый
      plain_refresh, token_digest, payload, expires_at = JsonWebToken.issue_refresh_token(user)
      user.refresh_tokens.create!(
        token_digest: token_digest,
        jti: payload[:jti],
        expires_at: expires_at
      )

      # Новый access token
      access_token = JsonWebToken.issue_access_token(user, ttl: 10.minutes)

      {
        access_token: access_token,
        refresh_token: plain_refresh,
        token_type: "Bearer",
        expires_in: 10.minutes.to_i
      }
    end

    # --- Logout / Revoke refresh token ---
    def self.revoke_refresh_token(user, token)
      digest = Digest::SHA256.hexdigest(token)
      token_record = user.refresh_tokens.find_by(token_digest: digest)
      token_record&.revoke!
    end
  end
end
