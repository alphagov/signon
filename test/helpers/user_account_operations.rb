module UserAccountOperations
  # usage: accept_invitation(password: "<new password>", invitation_token: "<token>")
  def accept_invitation(options)
    raise "Please provide password" unless options[:password]
    raise "Please provide invitation token" unless options[:invitation_token]

    signout
    visit accept_user_invitation_path(invitation_token: options[:invitation_token])
    fill_in "Passphrase", with: options[:password]
    fill_in "Confirm passphrase", with: options[:password]
    click_button "Set my passphrase"
  end

  # usage: confirm_email_change(password: "<new password>", confirmation_token: "<token>")
  def confirm_email_change(options)
    raise "Please provide password" unless options[:password]
    raise "Please provide confirmation token" unless options[:confirmation_token]

    signout
    visit user_confirmation_path(confirmation_token: options[:confirmation_token])
    assert_response_contains("Confirm a change to your account email")
    fill_in "Passphrase", with: options[:password]
    click_button "Confirm email change"
  end
end
