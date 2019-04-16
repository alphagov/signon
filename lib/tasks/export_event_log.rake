desc "Export the event log as a CSV"
task :export_event_log, %i[min_id max_id] => :environment do |_, args|
  USAGE_MESSAGE = "usage: rake export_event_log[<min_id>, <max_id>]".freeze
  abort USAGE_MESSAGE unless args[:min_id] && args[:max_id]

  path = "#{ENV['GOVUK_APP_ROOT'] || Rails.root}/reports"
  EventLogPresenter.new(min_id, max_id).write_csv(path)

  puts "Report successfully generated inside #{path} !"
end
