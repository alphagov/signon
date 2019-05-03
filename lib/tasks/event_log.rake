namespace :event_log do
  desc "Export the event log as a CSV"
  task :export, %i[min_id max_id] => :environment do |_, args|
    USAGE_MESSAGE = "usage: rake event_log:export[<min_id>, <max_id>]".freeze
    abort USAGE_MESSAGE unless args[:min_id] && args[:max_id]

    path = "#{ENV['GOVUK_APP_ROOT'] || Rails.root}/reports"
    EventLogPresenter.new(min_id, max_id).write_csv(path)

    puts "Report successfully generated inside #{path}"
  end

  desc "Delete all events in the event log older than 2 years"
  task delete_logs_older_than_two_years: :environment do
    delete_count = EventLog.where("created_at < ?", 2.years.ago).delete_all
    puts "#{delete_count} event log entries deleted"
  end
end
