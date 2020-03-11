class CreateApiUsersSupportAppPermission < ActiveRecord::Migration
  class SupportedPermission < ApplicationRecord
    belongs_to :application, class_name: "Doorkeeper::Application"
  end

  def up
    support = ::Doorkeeper::Application.find_by(name: "Support")
    if support
      SupportedPermission.create!(application: support, name: "api_users") if support
    end
  end
end
