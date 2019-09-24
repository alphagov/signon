require "csv"

class UserSuspensionsExporter
  def self.call(*args)
    new(*args).export_suspensions
  end

  def initialize(export_dir, users_since_date, suspensions_since_date, logger = Rails.logger)
    @export_dir = export_dir
    @users_since_date = users_since_date
    @suspensions_since_date = suspensions_since_date
    @logger = logger
  end

  def export_suspensions
    event_ids = [EventLog::ACCOUNT_AUTOSUSPENDED, EventLog::ACCOUNT_UNSUSPENDED].map(&:id)

    CSV.open(file_path, "wb", headers: true) do |csv|
      csv << ["Name", "Email", "Organisation", "Role", "Created at", "Auto-suspended at", "Unsuspended at", "Unsuspended by"]
      User.where("created_at > ?", users_since_date).order(:name).find_each do |user|
        org_name = user.organisation ? user.organisation.name : ""
        # because the suspension and the unsuspension are separate
        # events, and the suspension comes first, we need to store it
        # and only emit the CSV line when we get to the unsuspension.
        suspended_at = nil
        EventLog.order("created_at ASC").where(uid: user.uid, event_id: event_ids).where("created_at > ?", suspensions_since_date).find_each do |event|
          case event.event_id
          when EventLog::ACCOUNT_AUTOSUSPENDED.id
            suspended_at = event.created_at
          when EventLog::ACCOUNT_UNSUSPENDED.id
            # if a user was suspended before the
            # 'suspensions_since_date' and unsuspended after, we'll
            # see an unsuspend event with no corresponding suspend.
            if suspended_at
              csv << [user.name, user.email, org_name, user.role, user.created_at, suspended_at, event.created_at, event.initiator.email]
            end
            suspended_at = nil
          end
        end
        # if we have a non-nil 'suspended_at' here, then the user is
        # still suspended.
        if suspended_at
          csv << [user.name, user.email, org_name, user.role, user.created_at, suspended_at, "", ""]
        end
      end
    end

    logger.info("User suspensions exported to #{file_path}")
  end

private

  attr_reader :applications, :export_dir, :users_since_date, :suspensions_since_date, :logger

  def file_path
    File.join(export_dir, "#{Time.zone.now.to_s(:number)}-suspensions.csv")
  end
end
