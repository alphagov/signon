class BatchInvitationPermissionsController < ApplicationController
  include UserPermissionsControllerMethods
  before_action :authenticate_user!
  before_action :load_batch_invitation
  before_action :authorise_to_manage_permissions
  before_action :prevent_updating

  def new; end

  def create
    @batch_invitation.supported_permission_ids = params[:user][:supported_permission_ids] if params[:user]

    @batch_invitation.save!

    @batch_invitation.enqueue
    flash[:notice] = "Scheduled invitation of #{@batch_invitation.batch_invitation_users.count} users"
    redirect_to batch_invitation_path(@batch_invitation)
  end

private

  def load_batch_invitation
    @batch_invitation = current_user.batch_invitations.find(params[:batch_invitation_id])
  end

  def authorise_to_manage_permissions
    authorize @batch_invitation, :manage_permissions?
  end

  def prevent_updating
    if @batch_invitation.has_permissions?
      flash[:alert] = "Permissions have already been set for this batch of users"
      redirect_to batch_invitation_path(@batch_invitation)
    end
  end
end
