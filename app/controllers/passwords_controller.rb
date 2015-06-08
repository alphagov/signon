class PasswordsController < Devise::PasswordsController
  before_filter :record_password_reset_request, only: :create

  # overrides http://git.io/sOhoaA to prevent expirable from
  # intercepting reset password flow for a partially signed-in user
  def require_no_authentication
    if (params[:reset_password_token] || params[:forgot_expired_passphrase]) &&
      current_user && current_user.need_change_password?
      sign_out(current_user)
    end
    super
  end

  def update
    super do |resource|
      unless resource.valid?
        render 'devise/passwords/reset_error' and return
      end
    end
  end

  private
    def record_password_reset_request
      user_from_params = User.find_by_email(params[:user][:email]) if params[:user].present?
      EventLog.record_event(user_from_params, EventLog::PASSPHRASE_RESET_REQUEST) if user_from_params
      Statsd.new(::STATSD_HOST).increment(
        "#{::STATSD_PREFIX}.users.password_reset_request"
      )
    end
end
