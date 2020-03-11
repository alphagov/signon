class RemoveSupportAppErtpPermission < ActiveRecord::Migration
  class SupportedPermission < ApplicationRecord; end
  class Permission < ApplicationRecord
    serialize :permissions, Array
  end

  def up
    support = ::Doorkeeper::Application.find_by(name: "Support")

    unless support.nil?
      permission = SupportedPermission.find_by(application_id: support.id, name: "ertp")
      permission.delete unless permission.nil?

      # remove user permissions
      all_support_perms = Permission.where(application_id: support.id)
      ertp_support_perms = all_support_perms.select { |perm| perm.permissions.include?("ertp") }
      ertp_support_perms.each { |perm| perm.permissions -= %w[ertp]; perm.save! }
    end
  end
end
