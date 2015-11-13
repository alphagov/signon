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

  desc 'Fix remaining `event_id`s for renamed entries'
  task fix_remaining_event_ids: :environment do
    events = EventLog.where(event_id: nil, event: 'Account locked')
    puts "Updating #{events.size} events"

    events.update_all(event_id: EventLog::ACCOUNT_LOCKED.id)
    puts "All events were mapped"
  end
end
