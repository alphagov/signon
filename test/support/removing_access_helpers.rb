module RemovingAccessHelpers
  def assert_remove_access_from_self(application, current_user)
    assert_edit_self
    assert_remove_access(application, current_user, grantee_is_self: true)
  end

  def assert_remove_access_from_other_user(application, other_user)
    assert_edit_other_user(other_user)
    assert_remove_access(application, other_user)
  end

  def refute_remove_access_from_self(application)
    assert_edit_self
    refute_remove_access(application)
  end

  def refute_remove_access_from_other_user(application, other_user)
    assert_edit_other_user(other_user)
    refute_remove_access(application)
  end

private

  def assert_remove_access(application, grantee, grantee_is_self: false)
    click_link "Remove access to #{application.name}"
    click_button "Confirm"

    table_caption = grantee_is_self ? "Apps you don\\'t have access to" : "Apps #{grantee.name} does not have access to"
    apps_without_access_table = find("table caption[text()='#{table_caption}']").ancestor("table")

    assert apps_without_access_table.has_content?(application.name)
    assert_not grantee.has_access_to?(application)

    success_alert_description = grantee_is_self ? "Your access to #{application.name} has been removed." : "#{grantee.name}'s access to #{application.name} has been removed."
    assert_flash_content("Access removed")
    assert_flash_content(success_alert_description)
  end

  def refute_remove_access(application)
    assert_not page.has_link?("Remove access to #{application.name}")
  end
end
