require 'csv'

class BatchInvitationsController < ApplicationController
  include UserPermissionsControllerMethods
  before_filter :authenticate_user!

  helper_method :applications_and_permissions
  helper_method :recent_batch_invitations

  def new
    @batch_invitation = BatchInvitation.new(organisation_id: current_user.organisation_id)
    authorize @batch_invitation
  end

  def create
    @batch_invitation = BatchInvitation.new(user: current_user, organisation_id: params[:batch_invitation][:organisation_id])
    @batch_invitation.supported_permission_ids = params[:user][:supported_permission_ids] if params[:user]
    grant_default_permissions(@batch_invitation)
    authorize @batch_invitation

    unless file_uploaded?
      flash[:alert] = "You must upload a file"
      render :new
      return
    end

    begin
      csv = CSV.parse(params[:batch_invitation][:user_names_and_emails].read, headers: true)
    rescue CSV::MalformedCSVError => e
      flash[:alert] = "Couldn't understand that file: #{e.message}"
      render :new
      return
    end
    if csv.size < 1 # headers: true means .size is the number of data rows
      flash[:alert] = "CSV had no rows."
      render :new
      return
    elsif %w(Name Email).any? { |required_header| csv.headers.exclude?(required_header) }
      flash[:alert] = "CSV must have headers including 'Name' and 'Email'"
      render :new
      return
    end

    @batch_invitation.save
    csv.each do |row|
      BatchInvitationUser.create(batch_invitation: @batch_invitation, name: row["Name"], email: row["Email"])
    end
    @batch_invitation.enqueue
    flash[:notice] = "Scheduled invitation of #{@batch_invitation.batch_invitation_users.count} users"
    redirect_to batch_invitation_path(@batch_invitation)
  end

  def show
    @batch_invitation = BatchInvitation.find(params[:id])
    authorize @batch_invitation
  end

  private

  def recent_batch_invitations
    @_recent_batch_invitations ||= BatchInvitation.where("created_at > '#{3.days.ago}'").order("created_at desc")
  end

  def file_uploaded?
    if params[:batch_invitation].nil? || params[:batch_invitation][:user_names_and_emails].nil?
      false
    elsif ! params[:batch_invitation][:user_names_and_emails].respond_to?(:read)
      # IO objects should respond to `read`
      false
    else
      true
    end
  end

  def grant_default_permissions(batch_invitation)
    SupportedPermission.default.each do |default_permission|
      batch_invitation.supported_permissions << default_permission
    end
  end
end
