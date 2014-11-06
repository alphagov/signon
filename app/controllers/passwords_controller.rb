class PasswordsController < Devise::PasswordsController
  before_filter :record_password_reset_request, only: :create

  def edit
    self.resource = resource_class.where(reset_password_token: params[:reset_password_token]).first
    unless self.resource && self.resource.reset_password_period_valid?
      render 'devise/passwords/reset_error' and return
    end

    # Unfortunately (and surprisingly) the model method to change the reset password
    # token is protected. It seems better to break that protection than to reimplement
    # the same feature ourselves.
    self.resource.__send__(:generate_reset_password_token!)
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
