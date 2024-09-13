module GrantingAccessHelpers
  def assert_grant_access_to_self(application, current_user)
    assert_edit_self
    assert_grant_access(application, current_user, grantee_is_self: true)
  end

  def assert_grant_access_to_other_user(application, other_user)
    assert_edit_other_user(other_user)
    assert_grant_access(application, other_user)
  end

  def refute_grant_access_to_self(application)
    assert_edit_self
    refute_grant_access(application)
  end

  def refute_grant_access_to_other_user(application, other_user)
    assert_edit_other_user(other_user)
    refute_grant_access(application)
  end

private

  def assert_grant_access(application, grantee, grantee_is_self: false)
    click_button "Grant access to #{application.name}"

    table_caption = grantee_is_self ? "Apps you have access to" : "Apps #{grantee.name} has access to"
    app_with_access_table = find("table caption[text()='#{table_caption}']").ancestor("table")

    assert app_with_access_table.has_content?(application.name)
    assert grantee.has_access_to?(application)
    success_banner_caption = grantee_is_self ? "You have been granted access to #{application.name}." : "#{grantee.name} has been granted access to #{application.name}."
    assert_flash_content("Access granted")
    assert_flash_content(success_banner_caption)
  end

  def refute_grant_access(application)
    assert_not page.has_link?("Grant access to #{application.name}")
  end
end
