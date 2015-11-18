require 'test_helper'

class PopulateEventIdsTest < ActionDispatch::IntegrationTest
  context 'for a bunch of events without `event_id`' do
    setup do
      user = create(:user)

      event_types = [
        EventLog::TWO_STEP_ENABLED,
        EventLog::SUCCESSFUL_LOGIN,
        EventLog::UNSUCCESSFUL_LOGIN,
        EventLog::TWO_STEP_RESET,
      ]

      @events = event_types.map do |event|
        EventLog.new(uid: user.uid, event: event.description).tap do |event|
          # save these in the state they are in production
          # i.e. without an associated `event_id`
          event.save(validate: false)
        end
      end
    end

    should 'accurately populate the `event_id` attribute' do
      EventIdPopulator.populate

      @events.map(&:reload).each do |event|
        # ensure this won't fall back on the persisted attribute
        event.event = nil

        assert_equal event.event, event.entry.description
      end
    end
  end
end
