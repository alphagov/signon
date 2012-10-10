class PasswordsController < Devise::PasswordsController
  def create
    self.resource = resource_class.send_reset_password_instructions(params[resource_name])
    flash.now[:alert] = t(:reset_notification)
    Statsd.new(::STATSD_HOST).increment(
      "#{::STATSD_PREFIX}.users.password_reset_request"
    )
    render action: 'new'
  end
end
