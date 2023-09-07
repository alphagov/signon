class BatchInvitationPermissionsController < ApplicationController
  include UserPermissionsControllerMethods
  before_action :authenticate_user!
  before_action :load_batch_invitation
  before_action :authorise_to_manage_permissions

  helper_method :applications_and_permissions

  def new; end

  def create
    @batch_invitation.supported_permission_ids = params[:user][:supported_permission_ids] if params[:user]
    grant_default_permissions(@batch_invitation)

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

  def grant_default_permissions(batch_invitation)
    SupportedPermission.default.each do |default_permission|
      batch_invitation.grant_permission(default_permission)
    end
  end
end
