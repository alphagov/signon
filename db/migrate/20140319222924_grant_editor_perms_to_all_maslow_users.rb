class GrantEditorPermsToAllMaslowUsers < ActiveRecord::Migration[4.2][4.2]
  class Permission < ActiveRecord::Base
    serialize :permissions, Array
  end
  class ::Doorkeeper::Application < ActiveRecord::Base; end

  def up
    maslow = ::Doorkeeper::Application.where(name: "Maslow").first

    unless maslow.nil?
      all_maslow_perms = Permission.where(
        "application_id = ? and permissions like ?",
        maslow.id,
        "%signin%")
      all_maslow_perms.each { |perm| perm.permissions += ["editor"]; perm.save! }
    end
  end
end
