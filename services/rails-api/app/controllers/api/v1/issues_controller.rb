# frozen_string_literal: true

module Api
  module V1
    class IssuesController < ApplicationController
      before_action :set_repository
      before_action :set_issue, only: [:show, :update, :close]

      # GET /api/v1/repos/:owner/:repo/issues
      def index
        issues = @repository.issues
                            .includes(:author, :assignees, :labels)
                            .page(params[:page])
                            .per(30)
        issues = issues.where(state: params[:state]) if params[:state].present?
        render json: issues, each_serializer: IssueSerializer
      end

      # GET /api/v1/repos/:owner/:repo/issues/:number
      def show
        render json: @issue, serializer: IssueSerializer
      end

      # POST /api/v1/repos/:owner/:repo/issues
      def create
        issue = @repository.issues.build(issue_params)
        issue.author = current_user
        issue.number = @repository.next_issue_number

        if issue.save
          KafkaProducer.publish("issue.created", issue.as_json)
          render json: issue, serializer: IssueSerializer, status: :created
        else
          render json: { errors: issue.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/repos/:owner/:repo/issues/:number
      def update
        if @issue.update(issue_params)
          render json: @issue, serializer: IssueSerializer
        else
          render json: { errors: @issue.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/repos/:owner/:repo/issues/:number/close
      def close
        @issue.update!(state: "closed", closed_at: Time.current)
        KafkaProducer.publish("issue.closed", @issue.as_json)
        render json: @issue, serializer: IssueSerializer
      end

      private

      def set_repository
        @repository = Repository.find_by!(owner: params[:owner], name: params[:repo])
      end

      def set_issue
        @issue = @repository.issues.find_by!(number: params[:number])
      end

      def issue_params
        params.permit(:title, :body, :state, label_ids: [], assignee_ids: [])
      end
    end
  end
end
