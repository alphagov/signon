class EnsureUserNameIsNotNullable < ActiveRecord::Migration
  def up
    change_column_null(:users, :name, false)
  end
end
