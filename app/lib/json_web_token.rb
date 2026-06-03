# app/lib/json_web_token.rb
class JsonWebToken
  SECRET_KEY = Rails.application.secret_key_base

  # Генерация JWT
  # payload: hash с данными
  # exp: время истечения (Time или ActiveSupport::Duration)
  def self.encode(payload, exp = nil)
    payload = payload.dup
    payload[:exp] = exp.to_i if exp
    JWT.encode(payload, SECRET_KEY)
  end

  # Декодирование JWT
  # Возвращает HashWithIndifferentAccess или nil если токен невалидный
  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::ExpiredSignature, JWT::DecodeError
    nil
  end

  # Удобный метод для создания access токена
  def self.issue_access_token(user, ttl: 10.minutes)
    payload = {
      user_id: user.id,
      jti: SecureRandom.uuid,
      type: "access"
    }

    encode(payload, ttl.from_now)
  end

  # Удобный метод для создания refresh токена
  # Возвращает plain токен, который нужно захешировать и сохранить в БД
  def self.issue_refresh_token(user, ttl: 30.days)
    payload = {
      user_id: user.id,
      jti: SecureRandom.uuid,
      type: "refresh"
    }

    token = SecureRandom.hex(32)
    token_digest = Digest::SHA256.hexdigest(token)
    expires_at = ttl.from_now

    [token, token_digest, payload, expires_at]
  end
end
