class CreateWorldPermissionsForWhitehall < ActiveRecord::Migration
  class SupportedPermission < ActiveRecord::Base
    belongs_to :application, class_name: 'Doorkeeper::Application'
  end

  def up
    whitehall = ::Doorkeeper::Application.find_by_name("Whitehall")
    if whitehall
      ['World Writer', 'World Editor'].each do |world_permission|
        SupportedPermission.create!(application: whitehall, name: world_permission)
      end
    end
  end
end
