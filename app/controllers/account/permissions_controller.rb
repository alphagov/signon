class Account::PermissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_application
  before_action :set_permissions, only: %i[edit update]

  include ApplicationPermissionsHelper

  def show
    authorize [:account, @application], :view_permissions?

    @permissions = @application
      .sorted_supported_permissions_grantable_from_ui
      .sort_by { |permission| current_user.has_permission?(permission) ? 0 : 1 }
  end

  def edit
    authorize [:account, @application], :edit_permissions?

    if @permissions.empty?
      flash[:alert] = "No permissions found for #{@application.name} that you are authorised to manage."
      return redirect_to account_applications_path
    end

    @shared_permissions_form_locals = {
      action: account_application_permissions_path(@application),
      application: @application,
      cancel_path: account_applications_path,
      user: current_user,
    }

    @split_assigned_and_unassigned_permissions = @permissions.count > 8

    if @split_assigned_and_unassigned_permissions
      @assigned_permissions = []
      @unassigned_permission_options = []
      @permissions.each do |permission|
        if current_user.has_permission?(permission)
          @assigned_permissions.push(permission)
        else
          @unassigned_permission_options.push({ text: permission.name, value: permission.id })
        end
      end
    end
  end

  def update
    authorize [:account, @application], :edit_permissions?

    selected_permission_ids = []

    if update_params[:supported_permission_ids]
      selected_permission_ids = update_params[:supported_permission_ids]
    elsif update_params[:new_permission_id]&.length&.> 0
      selected_permission_ids.concat(update_params[:current_permission_ids] || [], [update_params[:new_permission_id]])
    else
      flash[:alert] = "You must select a permission."
      redirect_to edit_account_application_permissions_path(@application)
      return
    end

    supported_permission_ids = UserUpdatePermissionBuilder.new(
      user: current_user,
      updatable_permission_ids: @permissions.pluck(:id),
      selected_permission_ids: selected_permission_ids.map(&:to_i),
    ).build

    UserUpdate.new(current_user, { supported_permission_ids: }, current_user, user_ip_address).call

    if update_params[:add_more] == "true"
      flash[:new_permission_name] = SupportedPermission.find(update_params[:new_permission_id]).name
      redirect_to edit_account_application_permissions_path(@application)
    else
      flash[:success_alert] = {
        message: "Permissions updated",
        description: permissions_updated_description(@application.id),
      }
      redirect_to account_applications_path
    end
  end

private

  def update_params
    params.require(:application).permit(:new_permission_id, :add_more, current_permission_ids: [], supported_permission_ids: [])
  end

  def set_application
    @application = Doorkeeper::Application.not_api_only.find(params[:application_id])
  end

  def set_permissions
    if current_user.govuk_admin?
      @permissions = @application.sorted_supported_permissions_grantable_from_ui(include_signin: false)
    elsif current_user.publishing_manager?
      @permissions = @application.sorted_supported_permissions_grantable_from_ui(include_signin: false, only_delegated: true)
    end
  end
end
