# https://raw.github.com/scambra/devise_invitable/master/app/controllers/devise/invitations_controller.rb
class Admin::InvitationsController < Devise::InvitationsController
  include UserPermissionsControllerMethods
  helper_method :applications_and_permissions

  before_filter :authenticate_user!
  before_filter :must_be_admin, only: [:new, :create]

  rescue_from AWS::SES::ResponseError do |exception|
    if exception.message =~ /Address blacklisted/i
      @exception = exception
      render "shared/address_blacklisted", status: 500
    else
      raise
    end
  end

  def create
    # Prevent an error when devise_invitable invites/updates an existing user,
    # and accepts_nested_attributes_for tries to create duplicate permissions.
    if self.resource = User.find_by_email(params[:user][:email])
      flash[:alert] = "User already invited. If you want to, you can click 'Resend signup email'."
      respond_with resource, :location => after_invite_path_for(resource)
    else
      self.resource = resource_class.invite!(translate_faux_signin_permission(params[resource_name]), current_inviter)
      if resource.errors.empty?
        set_flash_message :notice, :send_instructions, :email => self.resource.email
        respond_with resource, :location => after_invite_path_for(resource)
      else
        respond_with_navigational(resource) { render :new }
      end
    end
  end

  def resend
    user = User.find(params[:id])
    user.invite!
    flash[:notice] = "Resent account signup email to #{user.email}"
    redirect_to admin_users_path
  end

  private

    def must_be_admin
      if ! current_user.is_admin?
        flash[:alert] = "You must be an admin to do admin things."
        redirect_to root_path
      end
    end

    def after_invite_path_for(resource)
      admin_users_path
    end
end
