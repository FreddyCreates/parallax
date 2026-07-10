# frozen_string_literal: true

class JsonWebToken
  SECRET_KEY = ENV.fetch("JWT_SECRET_KEY") { Rails.application.credentials.secret_key_base }
  ALGORITHM = "HS256"
  EXPIRY = 24.hours

  class << self
    def encode(payload, exp = EXPIRY.from_now)
      payload[:exp] = exp.to_i
      payload[:iat] = Time.current.to_i
      JWT.encode(payload, SECRET_KEY, ALGORITHM)
    end

    def decode(token)
      decoded = JWT.decode(token, SECRET_KEY, true, algorithm: ALGORITHM)
      HashWithIndifferentAccess.new(decoded.first)
    end
  end
end
