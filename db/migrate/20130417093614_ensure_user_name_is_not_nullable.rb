class EnsureUserNameIsNotNullable < ActiveRecord::Migration[4.2][4.2]
  def up
    change_column_null(:users, :name, false)
  end
end
