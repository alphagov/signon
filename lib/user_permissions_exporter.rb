require "csv"

class UserPermissionsExporter
  attr_reader :applications, :export_dir, :logger

  def initialize(export_dir, logger = Rails.logger)
    @export_dir = export_dir
    @logger = logger
  end

  def export_signon
    CSV.open(signon_file_path, "wb", headers: true) do |csv|
      csv << ["Name", "Email", "Organisation", "Role", "Suspended at"]
      User.order(:name).each do |user|
        org_name = user.organisation ? user.organisation.name : ""
        suspended_at = user.suspended_at || ""
        csv << [user.name, user.email, org_name, user.role, suspended_at]
      end
    end

    logger.info("Signon roles exported to #{signon_file_path}")
  end

  def export(apps)
    @applications = Doorkeeper::Application.where("name in (?)", apps)
    users = User.order(:name).to_a

    # iterate over applications
    CSV.open(file_path, "wb", headers: true) do |csv|
      csv << headers

      applications.each do |app|
        users.each do |user|
          permissions = user.permissions_for(app)
          if permissions.present?
            row = {}
            row["Application"] = app.name if multiple_apps?
            row["Name"] = user.name
            row["Email"] = user.email
            row["Organisation"] = user.organisation.name if user.organisation
            row["Permissions"] = permissions.join(",")
            csv << row
          end
        end
      end
    end

    logger.info("Permissions exported to #{file_path}")
  end

  def signon_file_path
    File.join(export_dir, "#{Time.zone.now.to_s(:number)}-signon.csv")
  end

  def file_path
    File.join(export_dir, file_name)
  end


private

  def multiple_apps?
    applications.size > 1
  end

  def headers
    headings = %w(Name Email Organisation Permissions)
    headings.unshift "Application" if multiple_apps?
    headings
  end

  def file_name
    "#{Time.zone.now.to_s(:number)}-#{@applications.map { |a| a.name.parameterize }.join('-')}.csv"
  end
end
