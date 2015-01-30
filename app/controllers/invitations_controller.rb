# https://raw.github.com/scambra/devise_invitable/master/app/controllers/devise/invitations_controller.rb
class InvitationsController < Devise::InvitationsController
  before_filter :authenticate_user!
  after_filter :verify_authorized, except: [:edit, :update]

  include UserPermissionsControllerMethods
  helper_method :applications_and_permissions

  rescue_from Net::SMTPFatalError do |exception|
    if exception.message =~ /Address blacklisted/i
      @exception = exception
      render "shared/address_blacklisted", status: 500
    else
      raise
    end
  end

  def new
    authorize User
    super
  end

  def create
    # Prevent an error when devise_invitable invites/updates an existing user,
    # and accepts_nested_attributes_for tries to create duplicate permissions.
    if self.resource = User.find_by_email(params[:user][:email])
      authorize resource
      flash[:alert] = "User already invited. If you want to, you can click 'Resend signup email'."
      respond_with resource, :location => after_invite_path_for(resource)
    else
      # workaround for invitatable not providing a build_invitation which could be authorised before saving
      resource_params = params[resource_name]
      user = User.new(resource_params)
      user.organisation_id = resource_params[:organisation_id]
      authorize user

      self.resource = resource_class.invite!(resource_params, current_inviter)
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
    authorize user

    user.invite!
    flash[:notice] = "Resent account signup email to #{user.email}"
    redirect_to users_path
  end

  private

  def after_invite_path_for(resource)
    users_path
  end

end
