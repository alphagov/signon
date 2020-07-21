module ConfirmationTokenHelpers
  def token_sent_to(user)
    token = Devise.friendly_token
    user.confirmation_token = token
    user.save!(validate: false)
    token
  end
end
