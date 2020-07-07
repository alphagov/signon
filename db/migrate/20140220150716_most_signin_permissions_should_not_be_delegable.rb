class MostSigninPermissionsShouldNotBeDelegable < ActiveRecord::Migration[3.2]
  def up
    require "doorkeeper/application.rb"

    Doorkeeper::Application.where("name not in ('Content Planner', 'Support')").each do |application|
      application.signin_permission.tap { |p| p.delegatable = false }.save
    end
  end
end
