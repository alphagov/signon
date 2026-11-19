require "csv"

class BulkUpdate::BulkUpdateUserController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user

  respond_to :html

  def index; end

  def create
    fail_with("A CSV file is required") and return unless params[:csv_file]

    begin
      csv = CSV.parse(params[:csv_file].read, headers: true)
    rescue CSV::MalformedCSVError => e
      fail_with("CSV is malformed: #{e.message}") and return
    end

    fail_with("CSV file contains no data rows") and return if csv.count.zero?

    old_emails = csv.pluck("Old email")
    duplicate_old_emails = old_emails.compact.tally.select { |_, count| count > 1 }.keys

    if duplicate_old_emails.any?
      fail_with("Email addresses in file more than once: #{join_for_display(duplicate_old_emails)}") and return
    end

    users = User.where(email: old_emails.compact).index_by(&:email)
    missing_emails = old_emails - users.keys

    if missing_emails.any?
      fail_with("Email addresses in file that do not exist: #{join_for_display(missing_emails)}") and return
    end

    new_organisation_slugs = csv.pluck("New organisation").compact.uniq
    new_organisations = Organisation.where(slug: new_organisation_slugs).index_by(&:slug)
    missing_organisations = new_organisation_slugs - new_organisations.keys

    if missing_organisations.any?
      fail_with("New organisations in file that do not exist: #{join_for_display(missing_organisations)}") and return
    end

    closed_organisations = new_organisations.values.select(&:closed?)

    if closed_organisations.any?
      fail_with("New organisations that are closed: #{join_for_display(closed_organisations.map(&:slug))}") and return
    end

    duplicate_new_emails = csv.pluck("New email").compact.tally.select { |_, count| count > 1 }.keys

    if duplicate_new_emails.any?
      fail_with("New email addresses in file more than once: #{join_for_display(duplicate_new_emails)}") and return
    end

    users_failed_to_update = csv.filter_map do |row|
      row["Old email"] unless row_valid_for_update?(row, users, new_organisations)
    end

    if users_failed_to_update.any?
      fail_with("Failed to update: #{join_for_display(users_failed_to_update)}") and return
    end

    ActiveRecord::Base.transaction do
      csv.each do |row|
        users_failed_to_update << row["Old email"] unless UserUpdate.new(
          users[row["Old email"]],
          user_params_from_row(row, new_organisations),
          current_user,
          user_ip_address,
        ).call
      end

      raise ActiveRecord::Rollback if users_failed_to_update.any?
    end

    if users_failed_to_update.any?
      fail_with("Failed to update: #{join_for_display(users_failed_to_update)}")
    else
      flash[:success_alert] = {
        message: "Users updated",
        description: "#{users.size} #{users.size == 1 ? 'user has' : 'users have'} been updated.",
      }
      render :index
    end
  end

private

  def authorize_user
    authorize User, :bulk_update?
  end

  def fail_with(message)
    flash[:error] = message
    render :index
  end

  def join_for_display(values)
    values.map { |value| value.presence || "(blank)" }.join(", ")
  end

  def user_params_from_row(row, new_organisations)
    new_user_params = {}
    new_user_params[:email] = row["New email"] if row["New email"].present?
    new_user_params[:organisation] = new_organisations[row["New organisation"]] if row["New organisation"].present?
    new_user_params
  end

  # Validity check without the update's side effects, because
  # they'd be non-transactional and couldn't be rolled back
  def row_valid_for_update?(row, users, new_organisations)
    user = users[row["Old email"]]
    user.assign_attributes(user_params_from_row(row, new_organisations))
    valid = user.valid?
    user.restore_attributes
    valid
  end
end
