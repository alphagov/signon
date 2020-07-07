class AddSupportsPushUpdatesToApplications < ActiveRecord::Migration[3.2]
  def change
    add_column :oauth_applications, :supports_push_updates, :boolean, default: true
  end
end
