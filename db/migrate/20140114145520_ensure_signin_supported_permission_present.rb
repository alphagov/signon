class EnsureSigninSupportedPermissionPresent < ActiveRecord::Migration
  def up
    require 'enhancements/application.rb'

    Doorkeeper::Application.all.each do |application|
      next if application.supported_permissions.where(name: ['signin', 'Signin']).present?
      application.supported_permissions.create!(name: 'signin', delegatable: true)
    end
  end
end
