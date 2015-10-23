module PassPhraseSupport
  def change_password(options)
    # this method assumes that the user is logged in
    visit root_path
    click_link "Change your email or passphrase"
    fill_in "Current passphrase", with: options[:old]
    fill_in "New passphrase", with: options[:new]
    fill_in "Confirm new passphrase", with: options[:new_confirmation]
    click_button "Change passphrase"
  end

  def reset_expired_passphrase(from, to, confirmation)
    fill_in "Current passphrase",       with: from
    fill_in "New passphrase",           with: to
    fill_in "Confirm new passphrase",   with: confirmation
    click_button "Change passphrase"
  end

  def trigger_reset_for(email)
    visit new_user_password_path
    fill_in "Email", with: email
    click_button "Send me passphrase reset instructions"
  end

  def complete_password_reset(email, options)
    email.click_link("Change my passphrase")
    fill_in "New passphrase", with: options[:new_password]
    fill_in "Confirm new passphrase", with: options[:new_password]
    click_button "Change passphrase"
  end
end
