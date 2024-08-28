require "csv"

namespace :event_log do
  desc "Delete all events in the event log older than 2 years"
  task delete_logs_older_than_two_years: :environment do
    delete_count = EventLog.where("created_at < ?", 2.years.ago).delete_all
    puts "#{delete_count} event log entries deleted"
  end
end
