module UserHelpers
  def signin_with(user = nil, email: nil, password: nil, second_step: true, set_up_2sv: true)
    user ||= User.find_by(email: email)
    email ||= user.email
    password ||= user.password

    if user && user.require_2sv? && user.otp_secret_key.blank? && set_up_2sv
      user.update_attribute(:otp_secret_key, ROTP::Base32.random_base32)
    end

    fill_in "Email", with: email
    fill_in "Password", with: password
    click_button "Sign in"

    if second_step && user && user.otp_secret_key
      code = second_step == true ? ROTP::TOTP.new(user.otp_secret_key).now : second_step
      Timecop.freeze do
        fill_in :code, with: code
        click_button "Sign in"
      end
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

  def enter_2sv_code(secret)
    Timecop.freeze do
      fill_in "code", with: ROTP::TOTP.new(secret).now
      click_button "submit_code"
    end
  end
end
