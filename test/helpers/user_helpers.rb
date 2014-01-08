module UserHelpers  
  def signin(user)
    fill_in "Email", with: user.email
    fill_in "Passphrase", with: user.password
    click_button "Sign in"
  end

  def signout
    visit destroy_user_session_path
  end

  def admin_changes_email_address(options)
    visit edit_admin_user_path(options[:user])
    fill_in "Email", with: options[:new_email]
    click_button "Update User"
  end
end
