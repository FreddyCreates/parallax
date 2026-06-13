# frozen_string_literal: true

class CreateIssuesAndPullRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :issues do |t|
      t.references :repository, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.integer :number, null: false
      t.string :title, null: false
      t.text :body
      t.string :state, default: "open"
      t.datetime :closed_at

      t.timestamps
    end

    add_index :issues, [:repository_id, :number], unique: true
    add_index :issues, :state

    create_table :pull_requests do |t|
      t.references :repository, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.references :merged_by, foreign_key: { to_table: :users }
      t.integer :number, null: false
      t.string :title, null: false
      t.text :body
      t.string :state, default: "open"
      t.string :base_branch, null: false
      t.string :head_branch, null: false
      t.integer :additions, default: 0
      t.integer :deletions, default: 0
      t.integer :changed_files, default: 0
      t.datetime :merged_at
      t.datetime :closed_at

      t.timestamps
    end

    add_index :pull_requests, [:repository_id, :number], unique: true
    add_index :pull_requests, :state

    create_table :webhooks do |t|
      t.references :repository, null: false, foreign_key: true
      t.string :url, null: false
      t.string :secret, null: false
      t.string :content_type, default: "json"
      t.text :events, array: true
      t.boolean :active, default: true

      t.timestamps
    end

    create_table :ssh_keys do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :key, null: false
      t.string :fingerprint, null: false
      t.datetime :last_used_at

      t.timestamps
    end

    add_index :ssh_keys, :fingerprint, unique: true

    create_table :organizations do |t|
      t.string :name, null: false
      t.string :display_name
      t.text :description
      t.string :avatar_url

      t.timestamps
    end

    add_index :organizations, :name, unique: true

    create_table :organization_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.string :role, default: "member"

      t.timestamps
    end

    add_index :organization_memberships, [:user_id, :organization_id], unique: true
  end
end
