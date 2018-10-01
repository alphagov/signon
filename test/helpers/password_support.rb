module PasswordSupport
  def change_password(options)
    # this method assumes that the user is logged in
    visit root_path
    click_link "Change your email or password"
    fill_in "Current password", with: options[:old]
    fill_in "New password", with: options[:new]
    fill_in "Confirm new password", with: options[:new_confirmation]
    click_button "Change password"
  end

  def reset_expired_password(from, to, confirmation)
    fill_in "Current password",       with: from
    fill_in "New password",           with: to
    fill_in "Confirm new password",   with: confirmation
    click_button "Change password"
  end

  def trigger_reset_for(email)
    visit new_user_password_path
    fill_in "Email", with: email
    click_button "Send me password reset instructions"
  end

  def complete_password_reset(email, options)
    email.click_link("Change my password")
    fill_in "New password", with: options[:new_password]
    fill_in "Confirm new password", with: options[:new_password]
    click_button "Change password"
  end
end
