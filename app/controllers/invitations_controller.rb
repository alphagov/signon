# https://raw.github.com/scambra/devise_invitable/master/app/controllers/devise/invitations_controller.rb
class InvitationsController < Devise::InvitationsController
  before_filter :authenticate_user!
  after_filter :verify_authorized, except: [:edit, :update]

  include UserPermissionsControllerMethods
  helper_method :applications_and_permissions

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
      respond_with resource, location: after_invite_path_for(resource)
    else
      # workaround for invitatable not providing a build_invitation which could be authorised before saving
      user = User.new(resource_params)
      user.organisation_id = resource_params[:organisation_id]
      authorize user

      self.resource = resource_class.invite!(resource_params, current_inviter)
      if resource.errors.empty?
        set_flash_message :notice, :send_instructions, email: self.resource.email
        respond_with resource, location: after_invite_path_for(resource)
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

  # TODO: remove this method when we're on a version of devise_invitable which
  # no longer expects it to exist (v1.2.1 onwards)
  def build_resource
    self.resource = resource_class.new(resource_params)
  end

  def resource_params
    sanitised_params = UserParameterSanitiser.new(
      user_params: unsanitised_user_params,
      current_user_role: current_user_role,
    ).sanitise

    if params[:action] == "update"
      sanitised_params.merge(invitation_token: invitation_token)
    else
      sanitised_params
    end
  end

  # TODO: once we've upgraded Devise and DeviseInvitable, `resource_params`
  # hopefully won't be being called for actions like `#new` anymore and we
  # can change the following `params.fetch(:user)` to
  # `params.require(:user)`. See
  # https://github.com/scambra/devise_invitable/blob/v1.1.5/app/controllers/devise/invitations_controller.rb#L10
  # and
  # https://github.com/plataformatec/devise/blob/v2.2/app/controllers/devise_controller.rb#L99
  # for details :)
  def unsanitised_user_params
    params.fetch(:user, {})
  end

  # NOTE: `current_user` doesn't exist for `#edit` and `#update` actions as
  # implemented in our current (out-of-date) versions of Devise
  # (https://github.com/plataformatec/devise/blob/v2.2/app/controllers/devise_controller.rb#L117)
  # and DeviseInvitable
  # (https://github.com/scambra/devise_invitable/blob/v1.1.5/app/controllers/devise/invitations_controller.rb#L5)
  #
  # With the old attr_accessible approach, this would fall back to the
  # default whitelist (i.e. equivalent to the `:normal` role) and this
  # this preserves that behaviour. In fact, a user accepting an invitation
  # only needs to modify `password` and `password_confirmation` so we could
  # only permit those two params for the `edit` and `update` actions.
  def current_user_role
    current_user.try(:role).try(:to_sym) || :normal
  end

  def invitation_token
    unsanitised_user_params.fetch(:invitation_token, {})
  end

  def update_resource_params
    resource_params
  end
end
