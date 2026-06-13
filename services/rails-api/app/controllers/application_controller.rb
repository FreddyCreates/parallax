# frozen_string_literal: true

class ApplicationController < ActionController::API
  before_action :authenticate_request!

  private

  def authenticate_request!
    header = request.headers["Authorization"]
    token = header&.split(" ")&.last

    if token.nil?
      render json: { error: "Missing token" }, status: :unauthorized
      return
    end

    decoded = JsonWebToken.decode(token)
    @current_user = User.find(decoded[:user_id])
  rescue ActiveRecord::RecordNotFound, JWT::DecodeError, JWT::ExpiredSignature => e
    render json: { error: "Unauthorized: #{e.message}" }, status: :unauthorized
  end

  def current_user
    @current_user
  end
end
