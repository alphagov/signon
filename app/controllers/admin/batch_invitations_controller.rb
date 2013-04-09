require 'csv'

class Admin::BatchInvitationsController < Admin::BaseController
  include UserPermissionsControllerMethods
  helper_method :applications_and_permissions
  helper_method :recent_batch_invitations

  def new
    @batch_invitation = BatchInvitation.new
  end

  def create
    # TODO refactor
    @batch_invitation = BatchInvitation.new(user: current_user, applications_and_permissions: translate_faux_signin_permission(params[:user])[:permissions_attributes])

    user_names_and_emails_io = params[:batch_invitation].delete(:user_names_and_emails)
    unless user_names_and_emails_io.respond_to?(:read)
      flash[:alert] = "You must upload a file"
      render :new
      return
    end
    user_names_and_emails = []

    begin
      csv = CSV.parse(user_names_and_emails_io.read, headers: true)
    rescue CSV::MalformedCSVError => e
      flash[:alert] = "Couldn't understand that file: #{e.message}"
      render :new
      return
    end
    if csv.size < 1 # headers: true means .size is the number of data rows
      flash[:alert] = "CSV had no rows."
      render :new
      return
    elsif ["Name", "Email"].any? { |required_header| csv.headers.exclude?(required_header) }
      flash[:alert] = "CSV must have headers including 'Name' and 'Email'"
      render :new
      return
    end

    @batch_invitation.save
    csv.each do |row|
      # TODO consider https://github.com/zdennis/activerecord-import
      BatchInvitationUser.create(batch_invitation: @batch_invitation, name: row["Name"], email: row["Email"])
    end
    Delayed::Job.enqueue(BatchInvitation::Job.new(@batch_invitation.id))
    flash[:notice] = "Scheduled invitation of #{@batch_invitation.batch_invitation_users.count} users"
    redirect_to admin_batch_invitation_path(@batch_invitation)
  end

  def show
    @batch_invitation = BatchInvitation.find(params[:id])
  end

  private
  def recent_batch_invitations
    @_recent_batch_invitations ||= BatchInvitation.where("created_at > '#{3.days.ago}'").order("created_at desc")
  end
end
