class AddSupportsPushUpdatesToApplications < ActiveRecord::Migration[6.0]
  def change
    add_column :oauth_applications, :supports_push_updates, :boolean, default: true
  end
end
