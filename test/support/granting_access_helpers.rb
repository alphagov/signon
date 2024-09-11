module GrantingAccessHelpers
  def assert_grant_access(application, grantee, grantee_is_self: false)
    click_button "Grant access to #{application.name}"

    table_caption = grantee_is_self ? "Apps you have access to" : "Apps #{grantee.name} has access to"
    app_with_access_table = find("table caption[text()='#{table_caption}']").ancestor("table")

    assert app_with_access_table.has_content?(application.name)
    assert grantee.has_access_to?(application)
  end

  def refute_grant_access(application)
    assert_not page.has_link?("Grant access to #{application.name}")
  end
end
