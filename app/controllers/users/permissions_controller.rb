class Users::PermissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_application
  before_action :set_permissions, only: %i[edit update]

  def show
    authorize @user, :edit?

    @permissions = @application
      .sorted_supported_permissions_grantable_from_ui
      .sort_by { |permission| @user.has_permission?(permission) ? 0 : 1 }
  end

  def edit
    authorize UserApplicationPermission.for(user: @user, supported_permission: @application.signin_permission)

    @shared_permissions_form_locals = {
      action: user_application_permissions_path(@user, @application),
      application: @application,
      cancel_path: edit_user_path(@user),
      user: @user,
    }

    @split_assigned_and_unassigned_permissions = @permissions.count > 8

    if @split_assigned_and_unassigned_permissions
      @assigned_permissions = []
      @unassigned_permission_options = []
      @permissions.each do |permission|
        if @user.has_permission?(permission)
          @assigned_permissions.push(permission)
        else
          @unassigned_permission_options.push({ text: permission.name, value: permission.id })
        end
      end
    end
  end

  def update
    authorize UserApplicationPermission.for(user: @user, supported_permission: @application.signin_permission)

    selected_permission_ids = []

    if update_params[:supported_permission_ids]
      selected_permission_ids = update_params[:supported_permission_ids]
    elsif update_params[:new_permission_id]&.length&.> 0
      selected_permission_ids.concat(update_params[:current_permission_ids] || [], [update_params[:new_permission_id]])
    else
      flash[:alert] = "You must select a permission."
      redirect_to edit_user_application_permissions_path(@user, @application)
      return
    end

    supported_permission_ids = UserUpdatePermissionBuilder.new(
      user: @user,
      updatable_permission_ids: @permissions.pluck(:id),
      selected_permission_ids: selected_permission_ids.map(&:to_i),
    ).build

    # I think the `SupportedPermissionParameterFilter` in combination with the
    # change to the `SupportedPermissionPolicy` will prevent removing
    # non-delegatable permissions for publishing managers, so there may not need
    # to be any further changes to this file, but we'll need to test this carefully

    UserUpdate.new(@user, { supported_permission_ids: }, current_user, user_ip_address).call

    if update_params[:add_more] == "true"
      flash[:new_permission_name] = SupportedPermission.find(update_params[:new_permission_id]).name
      redirect_to edit_user_application_permissions_path(@user, @application)
    else
      flash[:application_id] = @application.id
      redirect_to user_applications_path(@user)
    end
  end

private

  def update_params
    params.require(:application).permit(:new_permission_id, :add_more, current_permission_ids: [], supported_permission_ids: [])
  end

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_application
    @application = Doorkeeper::Application.with_signin_permission_for(@user).not_api_only.find(params[:application_id])
  end

  def set_permissions
    # is this the best place to do this?
    if current_user.govuk_admin?
      @permissions = @application.sorted_supported_permissions_grantable_from_ui(include_signin: false)
    elsif current_user.publishing_manager?
      @permissions = @application.sorted_supported_permissions_grantable_from_ui(include_signin: false, only_delegatable: true)
    end
  end
end
