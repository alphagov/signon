class CreateWhitehallEditorSupportedPermission < ActiveRecord::Migration
  class SupportedPermission < ActiveRecord::Base
    belongs_to :application, class_name: "Doorkeeper::Application"
  end

  class Permission < ActiveRecord::Base
    serialize :permissions, Array
  end

  def up
    whitehall = ::Doorkeeper::Application.find_by_name("Whitehall")
    if whitehall
      permission_name = "Editor"
      permission = SupportedPermission.create!(application: whitehall, name: permission_name)
      Permission.where(application_id: whitehall.id).each do |permission|
        if permission.permissions.include?("signin")
          permission.permissions << permission_name
          permission.save!
        end
      end
    end
  end
end
