class Permission < ActiveRecord::Base
  belongs_to :user
  belongs_to :application, class_name: 'Doorkeeper::Application'
  serialize :permissions, Array

  validates_presence_of :application_id
  validates_presence_of :user_id
end
