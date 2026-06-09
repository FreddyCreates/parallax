# frozen_string_literal: true

module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_request!, only: [:login, :register]

      # POST /api/v1/auth/register
      def register
        user = User.new(user_params)
        if user.save
          token = JsonWebToken.encode(user_id: user.id)
          render json: { token: token, user: UserSerializer.new(user) }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/auth/login
      def login
        user = User.find_by(email: params[:email])
        if user&.authenticate(params[:password])
          token = JsonWebToken.encode(user_id: user.id)
          render json: { token: token, user: UserSerializer.new(user) }, status: :ok
        else
          render json: { error: "Invalid credentials" }, status: :unauthorized
        end
      end

      # POST /api/v1/auth/refresh
      def refresh
        token = JsonWebToken.encode(user_id: current_user.id)
        render json: { token: token }, status: :ok
      end

      private

      def user_params
        params.permit(:username, :email, :password, :password_confirmation)
      end
    end
  end
end
