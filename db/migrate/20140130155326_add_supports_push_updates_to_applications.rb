class AddSupportsPushUpdatesToApplications < ActiveRecord::Migration
  def change
    add_column :oauth_applications, :supports_push_updates, :boolean, default: true
  end
end
