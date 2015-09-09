module UserHelpers
  def signin(user_or_options)
    email = user_or_options.is_a?(Hash) ? user_or_options[:email] : user_or_options.email
    password = user_or_options.is_a?(Hash) ? user_or_options[:password] : user_or_options.password

    fill_in "Email", with: email
    fill_in "Passphrase", with: password
    click_button "Sign in"
  end

  def signin_with_2sv(user_or_options)
    signin(user_or_options)
    if user_or_options.is_a? Hash
      user = User.find_by(email: user_or_options[:email])
    else
      user = user_or_options
    end

    Timecop.freeze do
      fill_in :code, with: ROTP::TOTP.new(user.otp_secret_key).now
      click_button "Sign in"
    end
  end

  def signout
    visit destroy_user_session_path
  end

  def admin_changes_email_address(options)
    visit edit_user_path(options[:user].id)
    fill_in "Email", with: options[:new_email]
    click_button "Update User"
  end
end
