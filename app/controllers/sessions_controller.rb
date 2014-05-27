class SessionsController < Devise::SessionsController
  def destroy
    ReauthEnforcer.perform_on(current_user) if current_user
    super
  end

  def create
    log_event
    super
  end

  private

  def log_event
    if current_user.present?
      EventLog.record_event(current_user, EventLog::SUCCESSFUL_LOGIN)
    else
      user = User.find_by_email(params[:user][:email])
      EventLog.record_event(user, EventLog::UNSUCCESSFUL_LOGIN) if user
    end
  end
end
