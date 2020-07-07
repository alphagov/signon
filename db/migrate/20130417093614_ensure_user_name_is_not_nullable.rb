class EnsureUserNameIsNotNullable < ActiveRecord::Migration[3.2]
  def up
    change_column_null(:users, :name, false)
  end
end
