require "csv"

class BulkUpdate::BulkUpdateUserController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user

  respond_to :html

  def index; end

  def update
    begin
      csv = CSV.parse(params[:csv_file].read, headers: true)
    rescue CSV::MalformedCSVError => e
      flash[:alert] = "CSV is malformed: #{e.message}"
      render :index and return
    end

    old_emails = csv.pluck("Old email")
    users = User.where(email: old_emails)
    user_count = users.count
    missing_emails = old_emails - users.pluck(:email)

    if missing_emails.any?
      flash[:error] = "Email addresses in file that do not exist: #{missing_emails.join(', ')}"
      render :index and return
    end

    new_organisation_slugs = csv.pluck("New organisation").uniq
    new_organisations = Organisation.where(slug: new_organisation_slugs)
    missing_organisations = new_organisation_slugs - new_organisations.pluck(:slug)

    if missing_organisations.any?
      flash[:error] = "New organisations in file that do not exist: #{missing_organisations.join(', ')}"
      render :index and return
    end

    csv.each do |row|
      old_email = row["Old email"]
      new_email = row["New email"]
      new_organisation = row["New organisation"]

      new_user_params = {}
      new_user_params[:email] = new_email if new_email.present?
      new_user_params[:organisation] = new_organisations.find_by(slug: new_organisation) if new_organisation.present?

      UserUpdate.new(
        users.find_by(email: old_email),
        new_user_params,
        current_user,
        user_ip_address,
      ).call
    end

    flash[:success_alert] = {
      message: "Users updated",
      description: "#{user_count} users have been updated.",
    }

    render :index and return
  end

private

  def authorize_user
    authorize User, :bulk_update?
  end
end
