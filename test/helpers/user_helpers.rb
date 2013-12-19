module UserHelpers  
  def signin(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Passphrase", with: user.password
    click_button "Sign in"
  end

  def assert_response_contains(content)
    assert page.has_content?(content), page.body
  end
end
