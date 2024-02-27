class AddMissingApplicationCreatedAtTimestamps < ActiveRecord::Migration[7.0]
  def up
    Doorkeeper::Application.where(created_at: nil).update_all(created_at: Date.parse("2012-01-01"))
  end
end
