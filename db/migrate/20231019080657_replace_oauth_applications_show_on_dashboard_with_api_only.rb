class ReplaceOauthApplicationsShowOnDashboardWithApiOnly < ActiveRecord::Migration[7.0]
  def up
    add_column :oauth_applications, :api_only, :boolean, default: false, null: false

    update "UPDATE oauth_applications SET api_only = !show_on_dashboard"

    remove_column :oauth_applications, :show_on_dashboard
  end

  def down
    add_column :oauth_applications, :show_on_dashboard, :boolean, default: true, null: false

    update "UPDATE oauth_applications SET show_on_dashboard = !api_only"

    remove_column :oauth_applications, :api_only
  end
end
