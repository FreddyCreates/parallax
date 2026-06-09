# frozen_string_literal: true

module Api
  module V1
    class WebhooksController < ApplicationController
      before_action :set_repository

      # GET /api/v1/repos/:owner/:repo/hooks
      def index
        hooks = @repository.webhooks.page(params[:page]).per(30)
        render json: hooks
      end

      # POST /api/v1/repos/:owner/:repo/hooks
      def create
        hook = @repository.webhooks.build(webhook_params)
        hook.secret = SecureRandom.hex(32)

        if hook.save
          render json: hook, status: :created
        else
          render json: { errors: hook.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/repos/:owner/:repo/hooks/:id
      def destroy
        hook = @repository.webhooks.find(params[:id])
        hook.destroy
        head :no_content
      end

      private

      def set_repository
        @repository = Repository.find_by!(owner: params[:owner], name: params[:repo])
      end

      def webhook_params
        params.permit(:url, :content_type, events: [])
      end
    end
  end
end
