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

    outcomes = batch_invite(csv)

    if outcomes[:successes].any?
      flash[:notice] = "Created #{outcomes[:successes].size} users"
    end
    if outcomes[:failures].any?
      flash[:alert] = "Failed to create #{outcomes[:failures].size} users"
    end
    redirect_to admin_users_path
  end

  private
    def batch_invite(csv)
      attributes = translate_faux_signin_permission(params[:user])
      outcomes = { successes: [], prexisting: [], failures: [] }
      csv.each do |row|
        attributes = attributes.merge(name: row["Name"], email: row["Email"])
        if User.find_by_email(row["Email"])
          outcomes[:prexisting] << row
        else
          begin
            User.invite!(attributes, current_user)
            outcomes[:successes] << row
          rescue StandardError => e
            outcomes[:failures] << row
          end
        end
      end
      outcomes
    end
end
