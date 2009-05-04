class AddChainWithoutLoopLength < ActiveRecord::Migration
  def self.up
    add_column :pages, :chain_without_loop_length, :integer
    add_index  :pages, :chain_without_loop_length
  end

  def self.down
    remove_index :pages, :chain_without_loop_length
    remove_column :pages, :chain_without_loop_length
  end
end

