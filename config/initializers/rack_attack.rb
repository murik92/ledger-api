class Rack::Attack
  #
  # AUTH ENDPOINTS
  # 5 requests / minute / IP
  #
  throttle("auth/ip", limit: 5, period: 1.minute) do |request|
    if request.path == "/api/v1/login" ||
        request.path.start_with?("/api/v1/auth")
        request.ip
    end
  end

  # 
  # WRITE ENDPOINTS
  # 60 requests / minute / user
  #
  throttle("write/user", limit: 60, period: 1.minute) do |request|
    next unless %w[POST PUT PATCH DELETE].include?(request.request_method)

    auth_header = request.get_header("HTTP_AUTHORIZATION")
    token = auth_header&.split(" ")&.last

    next unless token

    payload = JsonWebToken.decode(token)

    payload[:user_id] if payload && payload[:type] == "access"
  end

  #
  # TRANSFERS
  # 10 requests / minute / user
  #
  throttle("transfers/user", limit: 10, period: 1.minute) do |request|
    next unless request.path == "/api/v1/transfers"
    next unless request.post?

    auth_header = request.get_header("HTTP_AUTHORIZATION")
    token = auth_header&.split(" ")&.last

    next unless token

    payload = JsonWebToken.decode(token)

    payload[:user_id] if payload && payload[:type] == "access"
  end
end
