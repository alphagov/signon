class SessionsController < Devise::SessionsController
  def destroy
    ReauthEnforcer.perform_on(current_user) if current_user
    super
  end
end
