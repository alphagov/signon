class UpdateSupportsPushUpdatesOnApplications < ActiveRecord::Migration[4.2]
  def up
    Doorkeeper::Application.update_all supports_push_updates: true
  end

  def down
    Doorkeeper::Application.update_all supports_push_updates: false
  end
end
