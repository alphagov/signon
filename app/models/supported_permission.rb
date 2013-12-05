class SupportedPermission < ActiveRecord::Base
  belongs_to :application, class_name: 'Doorkeeper::Application'

  validates_presence_of :name

  attr_accessible :application_id, :name, :delegatable
end
