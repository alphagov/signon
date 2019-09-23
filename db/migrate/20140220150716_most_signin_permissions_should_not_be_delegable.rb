class MostSigninPermissionsShouldNotBeDelegable < ActiveRecord::Migration
  def up
    require "enhancements/application.rb"

    Doorkeeper::Application.where("name not in ('Content Planner', 'Support')").each do |application|
      application.signin_permission.tap { |p| p.delegatable = false }.save
    end
  end
end
