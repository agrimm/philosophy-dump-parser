class AddRedirectStatus < ActiveRecord::Migration
  def self.up
    add_column :pages, :redirect, :boolean
  end

  def self.down
    remove_column :pages, :redirect
  end
end

