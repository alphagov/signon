class AddManageKeywordPermission < ActiveRecord::Migration
  def up
    unless panopticon.nil?
      SupportedPermission.create(application: panopticon, name: "manage_keywords")
    end
  end

  def down
    unless panopticon.nil?
      SupportedPermission.where(application_id: panopticon.id, name: "manage_keywords").delete_all
    end
  end

  def panopticon
    @panopticon ||= Doorkeeper::Application.find_by_name("Panopticon")
  end
end
