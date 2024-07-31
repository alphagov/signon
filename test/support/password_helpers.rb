module PasswordHelpers
  def change_password(options)
    # this method assumes that the user is logged in
    visit root_path
    click_link "Change your password"
    fill_in "Current password", with: options[:old]
    fill_in "New password", with: options[:new]
    fill_in "Confirm new password", with: options[:new_confirmation]
    click_button "Save password"
  end

  def trigger_reset_for(email)
    visit new_user_password_path
    fill_in "Email address", with: email
    click_button "Send email"
  end

  def complete_password_reset(email, options)
    visit_password_reset_url_in(email)
    fill_in "New password", with: options[:new_password]
    fill_in "Confirm new password", with: options[:new_password]
    click_button "Save password"
  end

  def visit_password_reset_url_in(email)
    reset_password_url = /\[Reset your password\.\]\((?<url>http.*)\)/.match(email.base.email.body.raw_source).named_captures["url"]
    visit reset_password_url
  end
end
