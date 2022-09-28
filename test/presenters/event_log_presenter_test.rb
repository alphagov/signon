require "test_helper"

class EventLogPresenterTest < ActiveSupport::TestCase
  should "correctly generates log lines for ids falling within the requested range (inclusive)" do
    created_at = Date.new(2018, 1, 1)
    (1..5).each { |i| create(:event_log, id: i, uid: "uid", event_id: EventLog::ACCOUNT_AUTOSUSPENDED.id, created_at: created_at) }

    presenter = EventLogPresenter.new(2, 4)
    csv_array = []
    presenter.build_csv(csv_array)

    expected_lines = [
      ["Event ID", "Event UID", "Created at", "Initiator", "Application", "Trailing message", "Event", "IP address", "User agent"],
      [2, "uid", created_at, nil, nil, nil, "Account auto-suspended", nil, nil],
      [3, "uid", created_at, nil, nil, nil, "Account auto-suspended", nil, nil],
      [4, "uid", created_at, nil, nil, nil, "Account auto-suspended", nil, nil],
    ]

    assert_equal csv_array, expected_lines
  end
end
