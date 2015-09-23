Warden::Manager.after_authentication do |user, auth, _options|
  if user.respond_to?(:need_two_step_verification?)
    cookie = auth.env["action_dispatch.cookies"].signed["remember_2sv_session"]
    unless cookie && cookie[:user_id] == user.id && cookie[:valid_until] > Time.now
      auth.session(:user)['need_two_step_verification'] = user.need_two_step_verification?
    end
  end
end
