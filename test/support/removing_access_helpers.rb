module RemovingAccessHelpers
  def assert_remove_access(application, grantee, grantee_is_self: false)
    click_link "Remove access to #{application.name}"
    click_button "Confirm"

    table_caption = grantee_is_self ? "Apps you don\\'t have access to" : "Apps #{grantee.name} does not have access to"
    apps_without_access_table = find("table caption[text()='#{table_caption}']").ancestor("table")

    assert apps_without_access_table.has_content?(application.name)
    assert_not grantee.has_access_to?(application)
  end

  def refute_remove_access(application)
    assert_not page.has_link?("Remove access to #{application.name}")
  end
end
