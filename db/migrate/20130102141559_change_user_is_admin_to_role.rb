class ChangeUserIsAdminToRole < ActiveRecord::Migration
  class User < ApplicationRecord; end

  def up
    add_column :users, :role, :string, default: "normal"
    User.where(is_admin: true).update_all("role = 'admin'")
    User.where(is_admin: false).update_all("role = 'normal'")
    remove_column :users, :is_admin
  end
end
