module Devise::Hooks::SetCurrentUser
  Warden::Manager.after_set_user(only: :set_user) do |user, _auth, _options|
    Current.user = user
  end
  Warden::Manager.before_logout do |_user, _auth, _options|
    Current.user = nil
  end
end
