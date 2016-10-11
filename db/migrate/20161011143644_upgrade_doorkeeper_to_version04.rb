class UpgradeDoorkeeperToVersion04 < ActiveRecord::Migration
  def change
    change_column :oauth_access_tokens, :resource_owner_id, :integer, :null => true
  end
end
