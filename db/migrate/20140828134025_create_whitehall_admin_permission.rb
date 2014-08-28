class CreateWhitehallAdminPermission < ActiveRecord::Migration
  class SupportedPermission < ActiveRecord::Base
    belongs_to :application, class_name: 'Doorkeeper::Application'
  end

  def up
    whitehall = ::Doorkeeper::Application.find_by_name("Whitehall")
    if whitehall
      SupportedPermission.create!(application: whitehall, name: 'GDS Administrator')
    end
  end
end
