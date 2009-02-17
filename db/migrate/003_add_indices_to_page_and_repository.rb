class AddIndicesToPageAndRepository < ActiveRecord::Migration
  def self.up
    add_index :pages, :title
    add_index :pages, [:local_id, :repository_id]
    add_index :pages, :total_backlink_count #To enable sorting to find entries with the most total backlinks
    add_index :pages, :direct_link_id
    add_index :pages, :repository_id
  end

  def self.down
  end
end

