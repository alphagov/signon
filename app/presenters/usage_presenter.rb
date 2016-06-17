require 'csv'

class UsagePresenter
  include UsersHelper

  attr_reader :start_date, :end_date

  def initialize(start_date, end_date)
    @start_date = start_date.beginning_of_day
    @end_date = end_date.end_of_day
  end

  def write_csv(path)
    CSV.open(File.join(path, "usage_report_#{start_date.to_date}_#{end_date.to_date}.csv"), "wb") do |csv|
      build_csv(csv)
    end
  end

private

  def build_csv(csv)
    csv << header_row
    start_date_m = start_date.beginning_of_month

    while start_date_m < end_date
      end_date_m = start_date_m.end_of_month

      active_users = User.where("created_at <= ? and (suspended_at is NULL or suspended_at > ?)", end_date_m, end_date_m).
        group(:organisation_id).count
      suspended_users = User.where("suspended_at <= ?", end_date_m).
        group(:organisation_id).count
      total_count = {}
      (active_users.keys | suspended_users.keys).each do |key|
        total_count[key] = {active: active_users[key], suspended: suspended_users[key]}
      end

      month = start_date_m.strftime("%B, %Y")
      orgs = Organisation.all.select(:id, :name).index_by(&:id)

      total_count.each do |org_id, count|
        csv << [month, orgs[org_id].try(:name), count[:active], count[:suspended]]
      end

      start_date_m = (start_date_m + 1.month).beginning_of_month
    end
  end

  def header_row
    [
      'Month',
      'Organisation',
      'Active Users',
      'Suspended Users'
    ]
  end
end
