class AddShowOnDashboardToApplications < ActiveRecord::Migration[5.1]
  def change
    add_column :oauth_applications, :show_on_dashboard, :boolean, default: true, null: false
  end
end
