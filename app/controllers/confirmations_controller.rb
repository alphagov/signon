# Copied from 
# https://github.com/plataformatec/devise/blob/v2.1.2/app/controllers/devise/confirmations_controller.rb#L19
class ConfirmationsController < Devise::ConfirmationsController
  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    if user_signed_in?
      self.resource = resource_class.confirm_by_token(params[:confirmation_token])
      if resource.errors.empty?
        set_flash_message(:notice, :confirmed) if is_navigational_format?
        sign_in(resource_name, resource)
        respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource_name, resource) }
      else
        respond_with_navigational(resource.errors, :status => :unprocessable_entity){ render :new }
      end
    else
      self.resource = find_user
      if !self.resource.persisted?
        respond_with_navigational(resource.errors, :status => :unprocessable_entity){ render :new }
      end
    end
  end

  def update
    self.resource = find_user
    if self.resource.valid_password?(params[:user][:password])
      self.resource = resource_class.confirm_by_token(params[:confirmation_token])
      if resource.errors.empty?
        set_flash_message(:notice, :confirmed) if is_navigational_format?
        sign_in(resource_name, resource)
        respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource_name, resource) }
      else
        respond_with_navigational(resource.errors, :status => :unprocessable_entity){ render :new }
      end
    else
      self.resource.errors[:password] << "was incorrect"
      render :show
    end
  end

  private
    def find_user
      resource_class.find_or_initialize_with_error_by(:confirmation_token, params[:confirmation_token])
    end
end
