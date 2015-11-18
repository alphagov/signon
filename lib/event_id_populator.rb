class EventIdPopulator
  def self.populate
    EventLog::EVENTS.each do |event|
      EventLog.where(event: event.description, event_id: nil).update_all(event_id: event.id)
    end
  end
end
