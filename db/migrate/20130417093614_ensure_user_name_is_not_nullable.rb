class EnsureUserNameIsNotNullable < ActiveRecord::Migration[6.0]
  def up
    change_column_null(:users, :name, false)
  end
end
