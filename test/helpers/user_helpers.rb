module UserHelpers  
  def signin(user_or_options)
    email = user_or_options.is_a?(Hash) ? user_or_options[:email] : user_or_options.email
    password = user_or_options.is_a?(Hash) ? user_or_options[:password] : user_or_options.password

    fill_in "Email", with: email
    fill_in "Passphrase", with: password
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
