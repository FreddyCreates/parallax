# frozen_string_literal: true

# MySQL 8.4 migration — Users table
class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :username, null: false, limit: 39
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :name
      t.text :bio
      t.string :avatar_url
      t.string :location
      t.string :company
      t.string :website
      t.boolean :admin, default: false
      t.datetime :last_login_at

      t.timestamps
    end

    add_index :users, :username, unique: true
    add_index :users, :email, unique: true
  end
end
