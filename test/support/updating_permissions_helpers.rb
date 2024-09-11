module UpdatingPermissionsHelpers
  def assert_update_permissions(application, grantee, grant: [], revoke: [])
    click_link "Update permissions for #{application.name}"

    grant.each { |new_permission| check new_permission.name }
    revoke.each { |old_permission| uncheck old_permission.name }

    click_button "Update permissions"

    assert_flash_content(grant.map(&:name))
    grant.each { |new_permission| assert grantee.has_permission?(new_permission) }

    refute_flash_content(revoke.map(&:name))
    revoke.each { |old_permission| assert_not grantee.has_permission?(old_permission) }
  end

  def refute_update_permissions(application, permissions)
    click_link "Update permissions for #{application.name}"

    permissions.each do |permission|
      assert_not page.has_field?(permission.name)
    end
  end
end
