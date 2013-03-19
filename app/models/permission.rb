class Permission < ActiveRecord::Base
  belongs_to :user
  belongs_to :application, class_name: 'Doorkeeper::Application'
  serialize :permissions, Array

  validates_presence_of :application_id
  validates_presence_of :user_id

  def synced!
    update_attributes(last_synced_at: Time.zone.now)
  end

  def sync_needed?
    updated_at > last_synced_at
  end
end
