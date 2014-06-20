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

  # Copied from https://github.com/plataformatec/devise/blob/v2.1.2/app/controllers/devise/passwords_controller.rb#L12
  # So that we can rescue from SES blacklist errors and behave normally 
  # (i.e. not giving away whether or not an account exists for the email)
  def create
    begin
      self.resource = resource_class.send_reset_password_instructions(resource_params)
    rescue Net::SMTPFatalError => exception
      if exception.message =~ /Address blacklisted/i
        self.resource = user_from_params
      else
        raise
      end
    end

    if successfully_sent?(resource)
      respond_with({}, :location => after_sending_reset_password_instructions_path_for(resource_name))
    else
      respond_with(resource)
    end
  end

  private
    def user_from_params
      User.find_by_email(params[:user][:email]) if params[:user].present?
    end

    def record_password_reset_request
      EventLog.record_event(user_from_params, EventLog::PASSPHRASE_RESET_REQUEST) if user_from_params
      Statsd.new(::STATSD_HOST).increment(
        "#{::STATSD_PREFIX}.users.password_reset_request"
      )
    end
end
