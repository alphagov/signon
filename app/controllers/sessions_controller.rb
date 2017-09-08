class SessionsController < Devise::SessionsController
  skip_before_action :handle_two_step_verification

  def destroy
    ReauthEnforcer.perform_on(current_user) if current_user
    super
  end

  def create
    log_event
    store_location_for('2sv', session[stored_location_key_for(:user)])
    super
  end

  private

  def log_event
    if current_user.present?
      EventLog.record_event(current_user, EventLog::SUCCESSFUL_LOGIN)
    else
      # Call to_s to flatten out any unexpected params (eg a hash).
      user = User.find_by_email(params[:user][:email].to_s)
      EventLog.record_event(user, EventLog::UNSUCCESSFUL_LOGIN) if user
    end
  end
end
