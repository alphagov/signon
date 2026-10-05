require "csv"

class BulkUpdate::BulkUpdateUserController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user

  respond_to :html

  def index; end

  def create
    unless params[:csv_file]
      flash[:error] = "A CSV file is required"
      render :index and return
    end

    begin
      csv = CSV.parse(params[:csv_file].read, headers: true)
    rescue CSV::MalformedCSVError => e
      flash[:alert] = "CSV is malformed: #{e.message}"
      render :index and return
    end

    old_emails = csv.pluck("Old email")
    duplicate_emails = old_emails.tally.select { |_, count| count > 1 }.keys

    if duplicate_emails.any?
      flash[:error] = "Email addresses in file more than once: #{duplicate_emails.join(', ')}"
      render :index and return
    end

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

    users_failed_to_update = []

    ActiveRecord::Base.transaction do
      csv.each do |row|
        old_email = row["Old email"]
        new_email = row["New email"]
        new_organisation = row["New organisation"]

        new_user_params = {}
        new_user_params[:email] = new_email if new_email.present?
        new_user_params[:organisation] = new_organisations.find_by(slug: new_organisation) if new_organisation.present?

        users_failed_to_update << old_email unless UserUpdate.new(
          users.find_by(email: old_email),
          new_user_params,
          current_user,
          user_ip_address,
        ).call
      end

      raise ActiveRecord::Rollback if users_failed_to_update.any?
    end

    if users_failed_to_update.any?
      flash[:error] = "Failed to update: #{users_failed_to_update.join(', ')}"

    else
      flash[:success_alert] = {
        message: "Users updated",
        description: "#{user_count} users have been updated.",
      }
    end

    render :index and return
  end

private

  def authorize_user
    authorize User, :bulk_update?
  end
end
