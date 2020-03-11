class GrantEditorPermsToAllMaslowUsers < ActiveRecord::Migration
  class Permission < ApplicationRecord
    serialize :permissions, Array
  end
  class ::Doorkeeper::Application < ApplicationRecord; end

  def up
    maslow = ::Doorkeeper::Application.where(name: "Maslow").first

    unless maslow.nil?
      all_maslow_perms = Permission.where(
        "application_id = ? and permissions like ?",
        maslow.id,
        "%signin%",
)
      all_maslow_perms.each { |perm| perm.permissions += %w[editor]; perm.save! }
    end
  end
end
