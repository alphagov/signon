module UpdatingPermissionsHelpers
  def assert_update_permissions_for_self(application, current_user, grant: [], revoke: [])
    assert_edit_self
    assert_update_permissions(application, current_user, grant:, revoke:)
  end

  def assert_update_permissions_for_other_user(application, other_user, grant: [], revoke: [])
    assert_edit_other_user(other_user)
    assert_update_permissions(application, other_user, grant:, revoke:)
  end

  def refute_update_permissions_for_self(application, permissions)
    assert_edit_self
    refute_update_permissions(application, permissions)
  end

  def refute_update_permissions_for_other_user(application, permissions, other_user)
    assert_edit_other_user(other_user)
    refute_update_permissions(application, permissions)
  end

  def refute_update_any_permissions_for_app_for_other_user(application, other_user)
    assert_edit_other_user(other_user)
    assert page.has_content?("#{other_user.name}'s applications")
    assert_not page.has_link?("Update permissions for #{application.name}")
  end

private

  def assert_update_permissions(application, grantee, grant: [], revoke: [])
    click_link "Update permissions for #{application.name}"

    grant.each { |new_permission| check new_permission.name }
    revoke.each { |old_permission| uncheck old_permission.name }

    click_button "Update permissions"

    assert_flash_content("Permissions updated")
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
