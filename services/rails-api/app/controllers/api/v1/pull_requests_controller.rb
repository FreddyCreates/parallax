# frozen_string_literal: true

module Api
  module V1
    class PullRequestsController < ApplicationController
      before_action :set_repository
      before_action :set_pull_request, only: [:show, :update, :merge]

      # GET /api/v1/repos/:owner/:repo/pulls
      def index
        pulls = @repository.pull_requests
                           .includes(:author, :reviewers)
                           .page(params[:page])
                           .per(30)
        pulls = pulls.where(state: params[:state]) if params[:state].present?
        render json: pulls, each_serializer: PullRequestSerializer
      end

      # GET /api/v1/repos/:owner/:repo/pulls/:number
      def show
        render json: @pull_request, serializer: PullRequestSerializer
      end

      # POST /api/v1/repos/:owner/:repo/pulls
      def create
        pr = @repository.pull_requests.build(pull_request_params)
        pr.author = current_user
        pr.number = @repository.next_pr_number

        if pr.save
          KafkaProducer.publish("pr.created", pr.as_json)
          render json: pr, serializer: PullRequestSerializer, status: :created
        else
          render json: { errors: pr.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/repos/:owner/:repo/pulls/:number
      def update
        if @pull_request.update(pull_request_params)
          render json: @pull_request, serializer: PullRequestSerializer
        else
          render json: { errors: @pull_request.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/repos/:owner/:repo/pulls/:number/merge
      def merge
        result = GitServiceClient.merge(
          owner: params[:owner],
          repo: params[:repo],
          base: @pull_request.base_branch,
          head: @pull_request.head_branch
        )

        if result[:success]
          @pull_request.update!(state: "merged", merged_at: Time.current, merged_by: current_user)
          KafkaProducer.publish("pr.merged", @pull_request.as_json)
          render json: @pull_request, serializer: PullRequestSerializer
        else
          render json: { error: result[:message] }, status: :conflict
        end
      end

      private

      def set_repository
        @repository = Repository.find_by!(owner: params[:owner], name: params[:repo])
      end

      def set_pull_request
        @pull_request = @repository.pull_requests.find_by!(number: params[:number])
      end

      def pull_request_params
        params.permit(:title, :body, :base_branch, :head_branch, reviewer_ids: [])
      end
    end
  end
end
