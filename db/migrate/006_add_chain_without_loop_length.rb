class AddChainWithoutLoopLength < ActiveRecord::Migration
  def self.up
    add_column :pages, :chain_without_loop_length, :integer
  end

  def self.down
    remove_column :pages, :chain_without_loop_length
  end
end

