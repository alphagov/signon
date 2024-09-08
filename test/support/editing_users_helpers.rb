module EditingUsersHelpers
  def assert_edit_self
    visit account_applications_path

    assert page.has_content?("GOV.UK apps")
  end

  def assert_edit_other_user(other_user)
    visit user_applications_path(other_user)

    assert page.has_content?("#{other_user.name}'s applications")
  end

  def refute_edit_other_user(other_user)
    visit user_applications_path(other_user)

    failure_flash = find("div[role='alert']")

    assert failure_flash.has_content?("You do not have permission to perform this action.")
  end
end
