# frozen_string_literal: true

module Api
  module V1
    class SearchController < ApplicationController
      # GET /api/v1/search
      def index
        query = params[:q]
        scope = params[:scope] || "all"

        results = case scope
                  when "code"
                    SearchService.search_code(query, current_user)
                  when "repos"
                    SearchService.search_repositories(query, current_user)
                  when "users"
                    SearchService.search_users(query)
                  when "issues"
                    SearchService.search_issues(query, current_user)
                  else
                    SearchService.search_all(query, current_user)
                  end

        render json: {
          total_count: results[:total],
          items: results[:items],
          scope: scope
        }
      end
    end
  end
end
