Warden::Manager.after_authentication do |user, auth, options|
  if user.respond_to?(:need_two_step_verification?)
    auth.session(:user)['need_two_step_verification'] = user.need_two_step_verification?
  end
end
