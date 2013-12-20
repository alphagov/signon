module UserHelpers  
  def signin(user)
    fill_in "Email", with: user.email
    fill_in "Passphrase", with: user.password
    click_button "Sign in"
  end
end
