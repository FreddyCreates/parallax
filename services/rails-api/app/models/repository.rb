# frozen_string_literal: true

class Repository < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_many :issues, dependent: :destroy
  has_many :pull_requests, dependent: :destroy
  has_many :webhooks, dependent: :destroy
  has_many :collaborators, through: :repository_collaborators, source: :user

  validates :name, presence: true, uniqueness: { scope: :owner_id }
  validates :name, format: { with: /\A[a-zA-Z0-9._-]+\z/ }

  scope :public_repos, -> { where(private: false) }
  scope :private_repos, -> { where(private: true) }

  def full_name
    "#{owner.username}/#{name}"
  end

  def next_issue_number
    (issues.maximum(:number) || 0) + 1
  end

  def next_pr_number
    (pull_requests.maximum(:number) || 0) + 1
  end
end
