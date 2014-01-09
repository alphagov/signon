module UserAccountOperations
  def accept_invitation(options)
    signout
    visit accept_user_invitation_path(invitation_token: options[:invitation_token])
    fill_in "Passphrase", with: options[:password]
    fill_in "Confirm passphrase", with: options[:password]
    click_button "Set my passphrase"
  end

  def confirm_email_change(options)
    signout
    visit user_confirmation_path(confirmation_token: options[:confirmation_token])
    assert_response_contains("Confirm a change to your account email")
    fill_in "Passphrase", with: options[:password]
    click_button "Confirm email change"
  end
end
