class RenameUsersRequires2sv < ActiveRecord::Migration[6.0]
  def change
    rename_column :users, :requires_2sv, :require_2sv
  end
end
