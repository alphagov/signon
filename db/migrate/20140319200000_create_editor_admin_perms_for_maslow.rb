class CreateEditorAdminPermsForMaslow < ActiveRecord::Migration
  class ::Doorkeeper::Application < ActiveRecord::Base; end
  class SupportedPermission < ActiveRecord::Base
    belongs_to :application, class_name: "Doorkeeper::Application"
  end

  def up
    maslow = ::Doorkeeper::Application.where(name: "Maslow").first
    if maslow
      SupportedPermission.create!(application: maslow, name: "editor")
      SupportedPermission.create!(application: maslow, name: "admin")
    end
  end
end
