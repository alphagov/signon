require 'csv'

class Admin::BatchInvitationsController < Admin::BaseController
  include UserPermissionsControllerMethods
  helper_method :applications_and_permissions

  def new
  end

  def create
    user_names_and_emails_io = params.delete(:user_names_and_emails)
    unless user_names_and_emails_io.respond_to?(:read)
      flash[:alert] = "You must upload a file"
      render :new
      return
    end
    user_names_and_emails = []

    begin
      csv = CSV.parse(user_names_and_emails_io, headers: true)
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

    bi = BatchInvitation.create(applications_and_permissions: params[:user][:permissions_attributes])
    csv.each do |row|
      # TODO consider https://github.com/zdennis/activerecord-import
      BatchInvitationUser.create(batch_invitation: bi, name: row["Name"], email: row["Email"])
    end
    Delayed::Job.enqueue(BatchInvitation::Job.new(bi.id))
    flash[:notice] = "Scheduled invitation of #{bi.batch_invitation_users.count} users"
    redirect_to admin_batch_invitation_path(bi)
  end

  def show
    @batch_invitation = BatchInvitation.find(params[:id])
    @status_message = "#{@batch_invitation.batch_invitation_users.processed.count} of #{@batch_invitation.batch_invitation_users.count} users processed"
  end
end
