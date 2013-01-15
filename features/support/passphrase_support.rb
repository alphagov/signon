module PassPhraseSupport
  def change_password(from, to, confirmation)
    visit root_path
    click_link "Change your passphrase"
    fill_in "Current passphrase", with: from
    fill_in "New passphrase", with: to
    fill_in "Confirm new passphrase", with: confirmation
    click_button "Change passphrase"
  end
end

World(PassPhraseSupport)