class MakeUsersSuspendable < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :suspended_at, :datetime
  end
end
