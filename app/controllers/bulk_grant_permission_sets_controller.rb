class BulkGrantPermissionSetsController < ApplicationController
  include UserPermissionsControllerMethods
  before_filter :authenticate_user!

  helper_method :applications_and_permissions

  def new
    @bulk_grant_permission_set = BulkGrantPermissionSet.new
    authorize @bulk_grant_permission_set
  end

  def create
    @bulk_grant_permission_set = BulkGrantPermissionSet.new(user: current_user)
    @bulk_grant_permission_set.supported_permission_ids = params[:user][:supported_permission_ids] if params[:user]
    authorize @bulk_grant_permission_set

    @bulk_grant_permission_set.save
    @bulk_grant_permission_set.enqueue
    flash[:notice] = "Scheduled grant of #{@bulk_grant_permission_set.supported_permission_ids.count} permissions to all users"
    redirect_to bulk_grant_permission_set_path(@bulk_grant_permission_set)
  end

  def show
    @bulk_grant_permission_set = BulkGrantPermissionSet.find(params[:id])
    authorize @bulk_grant_permission_set
  end
end
