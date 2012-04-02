class MakeUsersSuspendable < ActiveRecord::Migration
  def change
    add_column :users, :suspended_at, :datetime
  end
end
