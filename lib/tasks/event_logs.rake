namespace :event_logs do
  desc 'Populate `event_id` from mapped `event`'
  task populate_event_ids: :environment do
    puts "Updating #{EventLog.where(event_id: nil).size} events"

    EventIdPopulator.populate

    remaining = EventLog.where(event_id: nil).pluck(:event).uniq

    if remaining.present?
      puts "Some events could not be mapped:"
      puts remaining
    else
      puts "All events were mapped"
    end
  end
end
