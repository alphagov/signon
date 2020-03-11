class AddAdminSupportedPermissionToNeedoTron < ActiveRecord::Migration
  class SupportedPermission < ApplicationRecord
    belongs_to :application, class_name: "Doorkeeper::Application"
  end

  def change
    needotron = ::Doorkeeper::Application.find_by(name: "Need-o-Tron")
    if needotron
      SupportedPermission.create!(application: needotron, name: "admin")
    end
  end
end
