class CreateSupportAppPermissions < ActiveRecord::Migration
  class SupportedPermission < ActiveRecord::Base
    belongs_to :application, class_name: "Doorkeeper::Application"
  end

  def up
    support = ::Doorkeeper::Application.find_by_name("Support")
    if support
      %w[content_requesters campaign_requesters single_points_of_contact].each do |permission_name|
        SupportedPermission.create!(application: support, name: permission_name)
      end
    end
  end
end
