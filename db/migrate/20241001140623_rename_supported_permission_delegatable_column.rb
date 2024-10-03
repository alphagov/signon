class RenameSupportedPermissionDelegatableColumn < ActiveRecord::Migration[7.2]
  def change
    rename_column :supported_permissions, :delegatable, :delegated
  end
end
