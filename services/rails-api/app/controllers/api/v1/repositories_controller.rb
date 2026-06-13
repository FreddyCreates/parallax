# frozen_string_literal: true

module Api
  module V1
    class RepositoriesController < ApplicationController
      before_action :set_repository, only: [:show, :update, :destroy]

      # GET /api/v1/repos
      def index
        repos = current_user.repositories.page(params[:page]).per(30)
        render json: repos, each_serializer: RepositorySerializer
      end

      # GET /api/v1/repos/:owner/:name
      def show
        render json: @repository, serializer: RepositorySerializer
      end

      # POST /api/v1/repos
      def create
        repo = current_user.repositories.build(repository_params)
        if repo.save
          KafkaProducer.publish("repo.created", repo.as_json)
          GitServiceClient.init_repo(current_user.username, repo.name)
          render json: repo, serializer: RepositorySerializer, status: :created
        else
          render json: { errors: repo.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/repos/:owner/:name
      def update
        if @repository.update(repository_params)
          render json: @repository, serializer: RepositorySerializer
        else
          render json: { errors: @repository.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/repos/:owner/:name
      def destroy
        @repository.destroy
        KafkaProducer.publish("repo.deleted", { id: @repository.id })
        head :no_content
      end

      private

      def set_repository
        @repository = Repository.find_by!(owner: params[:owner], name: params[:name])
      end

      def repository_params
        params.permit(:name, :description, :private, :default_branch)
      end
    end
  end
end
