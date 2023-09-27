# https://raw.github.com/scambra/devise_invitable/master/app/controllers/devise/invitations_controller.rb
class InvitationsController < Devise::InvitationsController
  before_action :authenticate_inviter!, only: %i[new create resend]
  after_action :verify_authorized, only: %i[new create resend]

  layout "admin_layout", only: %i[edit update]

  include UserPermissionsControllerMethods
  helper_method :applications_and_permissions

  def new
    authorize User
    super
  end

  def create
    # Prevent an error when devise_invitable invites/updates an existing user,
    # and accepts_nested_attributes_for tries to create duplicate permissions.
    if (self.resource = User.find_by(email: params[:user][:email]))
      authorize resource
      flash[:alert] = "User already invited. If you want to, you can click 'Resend signup email'."
      respond_with resource, location: users_path
    else
      # workaround for invitatable not providing a build_invitation which could be authorised before saving
      all_params = resource_params
      all_params[:require_2sv] = new_user_requires_2sv(all_params.symbolize_keys)

      user = User.new(all_params)
      user.organisation_id = all_params[:organisation_id]
      authorize user

      self.resource = resource_class.invite!(all_params, current_inviter)
      if resource.errors.empty?
        grant_default_permissions(resource)
        set_flash_message :notice, :send_instructions, email: resource.email
        respond_with resource, location: after_invite_path_for(resource)
      else
        respond_with_navigational(resource) { render :new }
      end

      EventLog.record_account_invitation(@user, current_user)
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

  def after_invite_path_for(_resource)
    if new_user_requires_2sv(resource)
      users_path
    else
      require_2sv_user_path(resource)
    end
  end

  def resource_params
    sanitised_params = UserParameterSanitiser.new(
      user_params: unsanitised_user_params,
      current_user_role:,
    ).sanitise

    if params[:action] == "update"
      sanitised_params.to_h.merge(invitation_token:)
    else
      sanitised_params.to_h
    end
  end

  def unsanitised_user_params
    params.require(:user).permit(
      :name,
      :email,
      :organisation_id,
      :invitation_token,
      :password,
      :password_confirmation,
      :require_2sv,
      :role,
      supported_permission_ids: [],
    ).to_h
  end

  def current_user_role
    (current_user || User.new).role.to_sym
  end

  def invitation_token
    unsanitised_user_params.fetch(:invitation_token, {})
  end

  def update_resource_params
    resource_params
  end

  def grant_default_permissions(user)
    SupportedPermission.default.each do |default_permission|
      user.grant_permission(default_permission)
    end
  end

  def new_user_requires_2sv(params)
    (params[:organisation_id].present? && Organisation.find(params[:organisation_id]).require_2sv?) ||
      %w[superadmin admin organisation_admin super_organisation_admin].include?(params[:role])
  end
end
