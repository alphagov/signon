require "csv"

class BatchInvitationsController < ApplicationController
  before_action :authenticate_user!

  layout "admin_layout"

  def new
    @batch_invitation = BatchInvitation.new(organisation_id: current_user.organisation_id)
    authorize @batch_invitation
  end

  def create
    @batch_invitation = BatchInvitation.new(user: current_user, organisation_id: params[:batch_invitation][:organisation_id])
    authorize @batch_invitation

    unless file_uploaded?
      flash.now[:alert] = "You must upload a file"
      render :new
      return
    end

    begin
      csv = CSV.parse(params[:batch_invitation][:user_names_and_emails].read, headers: true)
    rescue CSV::MalformedCSVError => e
      flash.now[:alert] = "Couldn't understand that file: #{e.message}"
      render :new
      return
    end
    if csv.empty?
      flash.now[:alert] = "CSV had no rows."
      render :new
      return
    elsif %w[Name Email].any? { |required_header| csv.headers.exclude?(required_header) }
      flash.now[:alert] = "CSV must have headers including 'Name' and 'Email'"
      render :new
      return
    end

    csv.each do |row|
      batch_user_args = {
        batch_invitation: @batch_invitation,
        name: row["Name"],
        email: row["Email"],
        organisation_slug: row["Organisation"],
      }
      batch_user = BatchInvitationUser.new(batch_user_args)

      unless batch_user.valid?
        flash.now[:alert] = batch_users_error_message(batch_user)
        return render :new
      end

      @batch_invitation.batch_invitation_users << batch_user
    end

    @batch_invitation.save!

    redirect_to new_batch_invitation_permissions_path(@batch_invitation)
  end

  def show
    @batch_invitation = BatchInvitation.find(params[:id])
    authorize @batch_invitation
  end

private

  def file_uploaded?
    if params[:batch_invitation].nil? || params[:batch_invitation][:user_names_and_emails].nil?
      false
    elsif !params[:batch_invitation][:user_names_and_emails].respond_to?(:read)
      # IO objects should respond to `read`
      false
    else
      true
    end
  end

  def batch_users_error_message(batch_user)
    e = batch_user.errors.first

    if e.attribute == :email
      "One or more emails were invalid"
    else
      e.full_message
    end
  end
end
