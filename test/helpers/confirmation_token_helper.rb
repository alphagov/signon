module ConfirmationTokenHelper
  def token_sent_to(user)
    raw, enc = Devise.token_generator.generate(User, :confirmation_token)
    user.confirmation_token = enc
    user.save(validate: false)
    raw
  end
end
