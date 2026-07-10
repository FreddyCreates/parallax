# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_many :repositories, foreign_key: :owner_id
  has_many :issues, foreign_key: :author_id
  has_many :pull_requests, foreign_key: :author_id
  has_many :ssh_keys
  has_many :organization_memberships
  has_many :organizations, through: :organization_memberships

  validates :username, presence: true, uniqueness: true, length: { in: 3..39 }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  before_create :generate_avatar_url

  private

  def generate_avatar_url
    self.avatar_url ||= "https://avatars.parralax.ai/#{username}"
  end
end
