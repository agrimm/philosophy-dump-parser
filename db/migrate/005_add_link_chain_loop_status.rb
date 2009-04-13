class AddLinkChainLoopStatus < ActiveRecord::Migration
  def self.up
    add_column :link_chain_elements, :is_in_loop_portion, :boolean
  end

  def self.down
    remove_column :is_in_loop_portion
  end
end

