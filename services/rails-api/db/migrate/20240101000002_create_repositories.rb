# frozen_string_literal: true

class CreateRepositories < ActiveRecord::Migration[7.2]
  def change
    create_table :repositories do |t|
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.text :description
      t.boolean :private, default: false
      t.string :default_branch, default: "main"
      t.integer :stars_count, default: 0
      t.integer :forks_count, default: 0
      t.integer :issues_count, default: 0
      t.string :language
      t.bigint :size_bytes, default: 0
      t.datetime :pushed_at

      t.timestamps
    end

    add_index :repositories, [:owner_id, :name], unique: true
    add_index :repositories, :private
  end
end
