class PasswordsController < Devise::PasswordsController
  before_action :record_password_reset_request, only: :create # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :record_reset_page_loaded, only: :edit

  def edit
    super

    user = user_from_params
    unless user && user.reset_password_period_valid?
      record_reset_page_loaded_token_expired
      render "devise/passwords/reset_error"
    end
  end

  def update
    super do |resource|
      if resource.errors.empty?
        record_password_reset_success(resource)
      else
        record_password_reset_failure(resource)
      end
    end
  end

private

  def record_password_reset_request
    user = User.find_by(email: params[:user][:email]) if params[:user].present?
    EventLog.record_event(user, EventLog::PASSWORD_RESET_REQUEST, ip_address: true) if user
  end

  def record_reset_page_loaded
    EventLog.record_event(user_from_params, EventLog::PASSWORD_RESET_LOADED, ip_address: true) if user_from_params
  end

  def record_password_reset_success(user)
    EventLog.record_event(user, EventLog::SUCCESSFUL_PASSWORD_RESET, ip_address: true)
  end

  def record_reset_page_loaded_token_expired
    EventLog.record_event(user_from_params, EventLog::PASSWORD_RESET_LOADED_BUT_TOKEN_EXPIRED, ip_address: true) if user_from_params
  end

  def record_password_reset_failure(user)
    message = "(errors: #{user.errors.full_messages.join(', ')})".truncate(255)
    EventLog.record_event(user, EventLog::PASSWORD_RESET_FAILURE, trailing_message: message, ip_address: true)
  end

  def user_from_params
    token = Devise.token_generator.digest(self, :reset_password_token, params[:reset_password_token])
    User.find_by(reset_password_token: token)
  end
end
