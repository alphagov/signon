class SupportedPermission < ActiveRecord::Base
  belongs_to :application, class_name: 'Doorkeeper::Application'
end