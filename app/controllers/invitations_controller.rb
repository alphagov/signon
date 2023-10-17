# https://raw.github.com/scambra/devise_invitable/master/app/controllers/devise/invitations_controller.rb
class InvitationsController < Devise::InvitationsController
  before_action :authenticate_inviter!, only: %i[new create resend]
  after_action :verify_authorized, only: %i[new create resend]

  before_action :redirect_if_invitee_already_exists, only: :create
  before_action :configure_permitted_parameters, only: :create

  layout "admin_layout", only: %i[new create edit update]

  include UserPermissionsControllerMethods
  helper_method :applications_and_permissions

  def new
    authorize User

    self.resource = User.with_default_permissions
    render :new
  end

  def create
    authorize User

    all_params = invite_params
    all_params[:require_2sv] = invitee_requires_2sv(all_params)

    self.resource = resource_class.invite!(all_params, current_inviter)
    if resource.errors.empty?
      EventLog.record_account_invitation(resource, current_user)
      set_flash_message :notice, :send_instructions, email: resource.email
      respond_with resource, location: after_invite_path_for(resource)
    else
      respond_with_navigational(resource) { render :new }
    end
  end

  # rubocop:disable Lint/UselessMethodDefinition
  # Renders app/views/devise/invitations/edit.html.erb
  def edit
    super
  end

  def update
    super
  end

  def destroy
    super
  end
  # rubocop:enable Lint/UselessMethodDefinition

  def resend
    user = User.find(params[:id])
    authorize user

    user.invite!
    flash[:notice] = "Resent account signup email to #{user.email}"
    redirect_to users_path
  end

private

  def after_invite_path_for(_)
    if invitee_requires_2sv(resource)
      users_path
    else
      require_2sv_user_path(resource)
    end
  end

  def organisation(params)
    Organisation.find_by(id: params[:organisation_id])
  end

  def invitee_requires_2sv(params)
    organisation(params)&.require_2sv? || User.admin_roles.include?(params[:role])
  end

  def redirect_if_invitee_already_exists
    if (resource = User.find_by(email: params[:user][:email]))
      authorize resource
      flash[:alert] = "User already invited. If you want to, you can click 'Resend signup email'."
      respond_with resource, location: users_path
    end
  end

  def configure_permitted_parameters
    keys = [:name, :organisation_id, { supported_permission_ids: [] }]
    keys << :role if policy(User).assign_role?
    devise_parameter_sanitizer.permit(:invite, keys:)
  end
end
