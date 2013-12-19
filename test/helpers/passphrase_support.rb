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
    click_button "Change my passphrase"
  end
end
