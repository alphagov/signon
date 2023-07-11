class BulkGrantPermissionSetsController < ApplicationController
  layout "admin_layout"

  before_action :authenticate_user!

  def new
    @bulk_grant_permission_set = BulkGrantPermissionSet.new
    authorize @bulk_grant_permission_set
  end

  def create
    @bulk_grant_permission_set = BulkGrantPermissionSet.new(user: current_user)
    application = Doorkeeper::Application.find_by(id: params[:application_id])
    @bulk_grant_permission_set.supported_permission_ids = [application.signin_permission.id]
    authorize @bulk_grant_permission_set

    if @bulk_grant_permission_set.save
      @bulk_grant_permission_set.enqueue
      flash[:notice] = "Scheduled grant of #{@bulk_grant_permission_set.supported_permission_ids.count} permissions to all users"
      redirect_to bulk_grant_permission_set_path(@bulk_grant_permission_set)
    else
      flash.now[:alert] = "Couldn't schedule granting #{@bulk_grant_permission_set.supported_permission_ids.count} permissions to all users, please try again"
      render :new
    end
  end

  def show
    @bulk_grant_permission_set = BulkGrantPermissionSet.find(params[:id])
    authorize @bulk_grant_permission_set
  end
end
