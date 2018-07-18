require 'date'
require 'test_helper'

class UserSuspensionsExporterTest < ActionView::TestCase
  def setup
    @chips_org = create(:organisation, name: "Ministry of chips")
    @ketchup_org = create(:organisation, name: "Ministry of ketchup")
    @brown_sauce_org = create(:organisation, name: "Ministry of brown sauce")
    @bill = create(:user, name: "Bill", email: "bill@bill.com", role: "normal", organisation: @chips_org)
    @anne = create(:user, name: "Anne", email: "anne@anne.com", role: "superadmin", organisation: @ketchup_org)
    @mary = create(:user, name: "Mary", email: "mary@mary.com", role: "admin", organisation: @brown_sauce_org)

    # give bill multiple suspensions
    create(:event_log, uid: @bill.uid, event_id: EventLog::ACCOUNT_AUTOSUSPENDED.id, created_at: Date.new(2018, 1, 1))
    create(:event_log, uid: @bill.uid, event_id: EventLog::ACCOUNT_UNSUSPENDED.id, initiator_id: @anne.id, created_at: Date.new(2018, 1, 15))
    create(:event_log, uid: @bill.uid, event_id: EventLog::ACCOUNT_AUTOSUSPENDED.id, created_at: Date.new(2018, 1, 16))
    create(:event_log, uid: @bill.uid, event_id: EventLog::ACCOUNT_UNSUSPENDED.id, initiator_id: @mary.id, created_at: Date.new(2018, 1, 31))

    # suspend anne once
    create(:event_log, uid: @anne.uid, event_id: EventLog::ACCOUNT_AUTOSUSPENDED.id, created_at: Date.new(2018, 2, 1))

    # suspend mary twice without unsuspending between
    create(:event_log, uid: @mary.uid, event_id: EventLog::ACCOUNT_AUTOSUSPENDED.id, created_at: Date.new(2018, 3, 1))
    create(:event_log, uid: @mary.uid, event_id: EventLog::ACCOUNT_AUTOSUSPENDED.id, created_at: Date.new(2018, 3, 5))

    @tmpfile = Tempfile.new(%w(user_permissions_exporter_test_example csv))
    UserSuspensionsExporter.any_instance.stubs(:file_path).returns(@tmpfile.path)
  end

  def test_export_no_suspensions
    UserSuspensionsExporter.new(@tmpfile.path, Date.new(2019, 1, 1)).export_suspensions

    csv_data = CSV.read(@tmpfile.path)

    assert_equal ["Name", "Email", "Organisation", "Role", "Auto-suspended at", "Unsuspended at", "Unsuspended by"], csv_data[0]
    assert_equal 1, csv_data.count
  end

  def test_export_missing_unsuspension
    UserSuspensionsExporter.new(@tmpfile.path, Date.new(2018, 2, 15)).export_suspensions

    csv_data = CSV.read(@tmpfile.path)

    assert_equal ["Name", "Email", "Organisation", "Role", "Auto-suspended at", "Unsuspended at", "Unsuspended by"], csv_data[0]
    assert_equal ["Mary", "mary@mary.com", "Ministry of brown sauce", "admin", "2018-03-05 00:00:00 +0000", "", ""], csv_data[1]
    assert_equal 2, csv_data.count
  end

  def test_export_missing_suspension
    UserSuspensionsExporter.new(@tmpfile.path, Date.new(2018, 1, 17)).export_suspensions

    csv_data = CSV.read(@tmpfile.path)

    assert_equal ["Name", "Email", "Organisation", "Role", "Auto-suspended at", "Unsuspended at", "Unsuspended by"], csv_data[0]
    assert_equal ["Anne", "anne@anne.com", "Ministry of ketchup", "superadmin", "2018-02-01 00:00:00 +0000", "", ""], csv_data[1]
    assert_equal ["Mary", "mary@mary.com", "Ministry of brown sauce", "admin", "2018-03-05 00:00:00 +0000", "", ""], csv_data[2]
    assert_equal 3, csv_data.count
  end

  def test_export_all
    UserSuspensionsExporter.new(@tmpfile.path, Date.new(1970, 1, 1)).export_suspensions

    csv_data = CSV.read(@tmpfile.path)

    assert_equal ["Name", "Email", "Organisation", "Role", "Auto-suspended at", "Unsuspended at", "Unsuspended by"], csv_data[0]
    assert_equal ["Bill", "bill@bill.com", "Ministry of chips", "normal", "2018-01-01 00:00:00 +0000", "2018-01-15 00:00:00 +0000", "anne@anne.com"], csv_data[1]
    assert_equal ["Bill", "bill@bill.com", "Ministry of chips", "normal", "2018-01-16 00:00:00 +0000", "2018-01-31 00:00:00 +0000", "mary@mary.com"], csv_data[2]
    assert_equal ["Anne", "anne@anne.com", "Ministry of ketchup", "superadmin", "2018-02-01 00:00:00 +0000", "", ""], csv_data[3]
    assert_equal ["Mary", "mary@mary.com", "Ministry of brown sauce", "admin", "2018-03-05 00:00:00 +0000", "", ""], csv_data[4]
    assert_equal 5, csv_data.count
  end
end
