module Devise::Hooks::TwoStepVerification
  Warden::Manager.after_authentication do |user, auth, _options|
    if user.need_two_step_verification?
      cookie = auth.env["action_dispatch.cookies"].signed["remember_2sv_session"]
      valid = cookie &&
        cookie["user_id"] == user.id &&
        cookie["valid_until"] > Time.zone.now &&
        cookie["secret_hash"] == Digest::SHA256.hexdigest(user.otp_secret_key)
      unless valid
        auth.session(:user)["need_two_step_verification"] = user.need_two_step_verification?
      end
    end
  end
end
