# frozen_string_literal: true

# Elasticsearch-backed search service.
class SearchService
  ES_CLIENT = Elasticsearch::Client.new(
    url: ENV.fetch("ELASTICSEARCH_URL", "http://localhost:9200"),
    log: Rails.env.development?
  )

  class << self
    def search_code(query, user)
      results = ES_CLIENT.search(
        index: "code",
        body: {
          query: {
            bool: {
              must: [{ match: { content: query } }],
              filter: [{ terms: { repository_id: accessible_repo_ids(user) } }]
            }
          },
          highlight: { fields: { content: {} } },
          size: 30
        }
      )
      format_results(results)
    end

    def search_repositories(query, user)
      results = ES_CLIENT.search(
        index: "repositories",
        body: {
          query: {
            bool: {
              must: [
                { multi_match: { query: query, fields: ["name^3", "description", "topics"] } }
              ],
              filter: [
                { bool: { should: [
                  { term: { private: false } },
                  { terms: { id: accessible_repo_ids(user) } }
                ] } }
              ]
            }
          },
          size: 30
        }
      )
      format_results(results)
    end

    def search_users(query)
      results = ES_CLIENT.search(
        index: "users",
        body: {
          query: { multi_match: { query: query, fields: ["username^3", "name", "bio"] } },
          size: 30
        }
      )
      format_results(results)
    end

    def search_issues(query, user)
      results = ES_CLIENT.search(
        index: "issues",
        body: {
          query: {
            bool: {
              must: [{ multi_match: { query: query, fields: ["title^2", "body"] } }],
              filter: [{ terms: { repository_id: accessible_repo_ids(user) } }]
            }
          },
          size: 30
        }
      )
      format_results(results)
    end

    def search_all(query, user)
      {
        total: 0,
        items: {
          code: search_code(query, user)[:items],
          repos: search_repositories(query, user)[:items],
          users: search_users(query)[:items],
          issues: search_issues(query, user)[:items]
        }
      }
    end

    private

    def accessible_repo_ids(user)
      user.repositories.pluck(:id) +
        Repository.public_repos.pluck(:id)
    end

    def format_results(results)
      {
        total: results.dig("hits", "total", "value") || 0,
        items: results.dig("hits", "hits")&.map { |h| h["_source"] } || []
      }
    end
  end
end
