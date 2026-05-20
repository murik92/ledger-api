class JsonWebToken
  SECRET_KEY = Rails.application.secret_key_base

  def self.encode(payload)
    JWT.encode(
      payload,
      SECRET_KEY
    )
  end

  def self.decode(token)
    decoded_token = JWT.decode(
      token,
      SECRET_KEY
    )

    decoded_token.first
  end
end