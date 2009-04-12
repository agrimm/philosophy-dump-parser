class CreateLinkChainElements < ActiveRecord::Migration
  def self.up
    create_table :link_chain_elements do |t|
      t.integer :repository_id
      t.integer :originating_page_id
      t.integer :linked_page_id
      t.integer :chain_position_number
    end
    add_index :link_chain_elements, :repository_id
    add_index :link_chain_elements, [:originating_page_id, :repository_id]
    add_index :link_chain_elements, [:linked_page_id, :repository_id]
    add_index :link_chain_elements, [:chain_position_number, :repository_id]
  end

  def self.down
    drop_table :link_chain_elements
  end
end

