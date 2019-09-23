require "csv"
require "fileutils"

class EventLogPresenter
  attr_reader :min_id, :max_id, :file_system, :file_utils

  def initialize(min_id, max_id, file_system = File, file_utils = FileUtils)
    @min_id = min_id
    @max_id = max_id
    @file_system = file_system
    @file_utils = file_utils
  end

  def write_csv(path)
    file_utils.mkdir_p(path) unless file_system.directory?(path)

    CSV.open(file_system.join(path, "event_log_#{min_id}_#{max_id}.csv"), "wb") do |csv|
      build_csv(csv)
    end
  end

private

  def build_csv(csv)
    csv << header_row

    EventLog.includes(:initiator, :application, :user_agent).where("id >= ?", min_id).where("id <= ?", max_id).find_in_batches do |entries|
      entries.each do |entry|
        csv << [
          entry.id,
          entry.uid,
          entry.created_at,
          entry.initiator&.name,
          entry.application&.name,
          entry.trailing_message,
          entry.event,
          (entry.ip_address_string unless entry.ip_address.nil?),
          entry.user_agent&.user_agent_string,
        ]
      end
    end
  end

  def header_row
    [
      "Event ID",
      "Event UID",
      "Created at",
      "Initiator",
      "Application",
      "Trailing message",
      "Event",
      "IP address",
      "User agent",
    ]
  end
end
