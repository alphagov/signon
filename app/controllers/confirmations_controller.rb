# Copied from
# https://github.com/plataformatec/devise/blob/v2.1.2/app/controllers/devise/confirmations_controller.rb#L19
class ConfirmationsController < Devise::ConfirmationsController
  layout "admin_layout"

  def new
    handle_new_token_needed
  end

  def create
    handle_new_token_needed
  end

  # GET /users/confirmation?confirmation_token=abcdef
  def show
    if user_signed_in?
      if confirmation_user.persisted? && (current_user.email != confirmation_user.email)
        redirect_to root_path, alert: "It appears you followed a link meant for another user."
      else
        self.resource = resource_class.confirm_by_token(params[:confirmation_token])
        if resource.errors.empty?
          EventLog.record_event(resource, EventLog::EMAIL_CHANGE_CONFIRMED, ip_address: user_ip_address)
          set_flash_message(:notice, :confirmed) if is_navigational_format?
          sign_in(resource_name, resource)
          respond_with_navigational(resource) { redirect_to after_confirmation_path_for(resource_name, resource) }
        else
          respond_with_navigational(resource.errors, status: :unprocessable_entity) { handle_new_token_needed }
        end
      end
    else
      self.resource = confirmation_user
      unless resource.persisted?
        respond_with_navigational(resource.errors, status: :unprocessable_entity) { handle_new_token_needed }
      end
    end
  end

  def update
    self.resource = confirmation_user

    if resource.valid_password?(params[:user][:password])
      self.resource = resource_class.confirm_by_token(params[:confirmation_token])
      if resource.errors.empty?
        EventLog.record_event(resource, EventLog::EMAIL_CHANGE_CONFIRMED, ip_address: user_ip_address)
        set_flash_message(:notice, :confirmed) if is_navigational_format?
        sign_in(resource_name, resource)
        respond_with_navigational(resource) { redirect_to after_confirmation_path_for(resource_name, resource) }
      else
        respond_with_navigational(resource.errors, status: :unprocessable_entity) { handle_new_token_needed }
      end
    else
      resource.errors[:password] << "was incorrect"
      render :show
    end
  end

private

  def confirmation_user
    @confirmation_user ||= resource_class.find_or_initialize_by(confirmation_token: params[:confirmation_token])
  end

  def handle_new_token_needed
    path = user_signed_in? ? root_path : new_user_session_path
    redirect_to path, alert: "Couldn't confirm email change. Please contact support to request a new confirmation email."
  end
end
