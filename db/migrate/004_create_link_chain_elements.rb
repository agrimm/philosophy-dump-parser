class CreateLinkChainElements < ActiveRecord::Migration
  def self.up
    #do nothing
  end

  def self.down
    drop_table :link_chain_elements
  end
end

