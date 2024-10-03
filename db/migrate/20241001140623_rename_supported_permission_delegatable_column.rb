class RenameSupportedPermissionDelegatableColumn < ActiveRecord::Migration[7.2]
  def change
    rename_column :supported_permissions, :delegated, :delegated
  end
end
