class UserApplicationPermission < ActiveRecord::Base
  belongs_to :user
  belongs_to :application, class_name: 'Doorkeeper::Application'
  belongs_to :supported_permission

  validates_uniqueness_of :supported_permission_id, scope: [:user_id, :application_id]
end
