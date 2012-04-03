class PasswordsController < Devise::PasswordsController
  def create
    self.resource = resource_class.send_reset_password_instructions(params[resource_name])
    flash.now[:alert] = t(:reset_notification)
    render action: 'new'
  end
end
