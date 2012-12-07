class PasswordsController < Devise::PasswordsController
  before_filter :record_password_reset_request, only: :create

  # Copied from https://github.com/plataformatec/devise/blob/v2.1.2/app/controllers/devise/passwords_controller.rb#L12
  # So that we can rescue from SES blacklist errors and behave normally 
  # (i.e. not giving away whether or not an account exists for the email)
  def create
    begin
      self.resource = resource_class.send_reset_password_instructions(resource_params)
    rescue AWS::SES::ResponseError => exception
      if exception.message =~ /Address blacklisted/i
        self.resource = User.find_by_email(params[:user][:email])
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
    def record_password_reset_request
      Statsd.new(::STATSD_HOST).increment(
        "#{::STATSD_PREFIX}.users.password_reset_request"
      )
    end
end
