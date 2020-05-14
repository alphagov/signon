class SessionsController < Devise::SessionsController
  layout "admin_layout"

  skip_before_action :handle_two_step_verification

  def destroy
    ReauthEnforcer.perform_on(current_user) if current_user
    super
  end

  def create
    log_event
    store_location_for("2sv", session[stored_location_key_for(:user)])
    super
  end

private

  def log_event
    if current_user.present?
      user_agent_record_id = nil
      unless user_agent.nil?
        user_agent_record = UserAgent.find_or_create_by!(user_agent_string: user_agent)
        user_agent_record_id = user_agent_record.id
      end
      EventLog.record_event(
        current_user,
        EventLog::SUCCESSFUL_LOGIN,
        ip_address: user_ip_address,
        user_agent_id: user_agent_record_id,
      )
    else
      # Call to_s to flatten out any unexpected params (eg a hash).
      email = params[:user][:email].to_s
      user = User.find_by(email: email)
      if user
        EventLog.record_event(
          user,
          EventLog::UNSUCCESSFUL_LOGIN,
          ip_address: user_ip_address,
          user_agent_string: user_agent,
        )
      else
        EventLog.record_event(
          nil,
          EventLog::NO_SUCH_ACCOUNT_LOGIN,
          ip_address: user_ip_address,
          user_agent_string: user_agent,
          user_email_string: email,
        )
      end
    end
  end

  def user_agent
    request.headers["user-agent"]
  end
end
