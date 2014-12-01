require 'test_helper'

class UserPermissionsExporterTest < ActionView::TestCase

  def setup
    @chips_org = FactoryGirl.create(:organisation, name: "Ministry of chips")
    @ketchup_org = FactoryGirl.create(:organisation, name: "Ministry of ketchup")
    @brown_sauce_org = FactoryGirl.create(:organisation, name: "Ministry of brown sauce")
    @bill = FactoryGirl.create(:user, name: "Bill", email: "bill@bill.com", organisation: @chips_org,
                               suspended_at: Date.parse('2000-01-01'), reason_for_suspension: "Left Chips.org")
    @anne = FactoryGirl.create(:user, name: "Anne", email: "anne@anne.com", role: "superadmin", organisation: @ketchup_org)
    @mary = FactoryGirl.create(:user, name: "Mary", email: "mary@mary.com", role: "admin", organisation: @brown_sauce_org)

    @tmpfile = Tempfile.new(['user_permissions_exporter_test_example', 'csv'])
    UserPermissionsExporter.any_instance.stubs(:file_path).returns(@tmpfile.path)
    UserPermissionsExporter.any_instance.stubs(:signon_file_path).returns(@tmpfile.path)
  end

  def test_export_one_application
    foo_app = FactoryGirl.create(:application, name: "Foo")
    FactoryGirl.create(:permission, permissions: ["signin", "cook"], application: foo_app, user: @bill)
    FactoryGirl.create(:permission, permissions: ["signin", "administer", "add_vinegar"], application: foo_app, user: @anne)
    FactoryGirl.create(:permission, permissions: ["signin", "do_some_stuff"], application: foo_app, user: @mary)

    UserPermissionsExporter.new(@tmpfile.path).export(["Foo"])

    csv_data = CSV.read(@tmpfile.path)

    assert_equal %w(Name Email Organisation Permissions),                                     csv_data[0]
    assert_equal %w(Anne anne@anne.com Ministry\ of\ ketchup signin,administer,add_vinegar),  csv_data[1]
    assert_equal %w(Bill bill@bill.com Ministry\ of\ chips signin,cook),                      csv_data[2]
    assert_equal %w(Mary mary@mary.com Ministry\ of\ brown\ sauce signin,do_some_stuff),      csv_data[3]
  end

  def test_export_multiple_applications
    foo_app = FactoryGirl.create(:application, name: "Foo")
    bar_app = FactoryGirl.create(:application, name: "Bar")
    baz_app = FactoryGirl.create(:application, name: "Baz")

    FactoryGirl.create(:permission, permissions: ["signin", "cook"], application: foo_app, user: @bill)
    FactoryGirl.create(:permission, permissions: [], application: baz_app, user: @bill)
    FactoryGirl.create(:permission, permissions: ["signin", "administer", "add_vinegar"], application: foo_app, user: @anne)
    FactoryGirl.create(:permission, permissions: ["signin", "administer"], application: bar_app, user: @anne)
    FactoryGirl.create(:permission, permissions: ["signin", "do_some_stuff"], application: foo_app, user: @mary)
    FactoryGirl.create(:permission, permissions: ["signin", "administer"], application: bar_app, user: @mary)

    UserPermissionsExporter.new(@tmpfile.path).export(["Foo","Bar","Baz"])

    csv_data = CSV.read(@tmpfile.path)

    assert_equal %w(Application Name Email Organisation Permissions),                             csv_data[0]
    assert_equal %w(Bar Anne anne@anne.com Ministry\ of\ ketchup signin,administer),              csv_data[1]
    assert_equal %w(Bar Mary mary@mary.com Ministry\ of\ brown\ sauce signin,administer),         csv_data[2]
    assert_equal %w(Foo Anne anne@anne.com Ministry\ of\ ketchup signin,administer,add_vinegar),  csv_data[3]
    assert_equal %w(Foo Bill bill@bill.com Ministry\ of\ chips signin,cook),                      csv_data[4]
    assert_equal %w(Foo Mary mary@mary.com Ministry\ of\ brown\ sauce signin,do_some_stuff),      csv_data[5]
  end

  def test_export_signon
    UserPermissionsExporter.new(@tmpfile.path).export_signon

    csv_data = CSV.read(@tmpfile.path)

    assert_equal ["Name", "Email", "Organisation", "Role", "Suspended at"], csv_data[0]
    assert_equal ["Anne", "anne@anne.com", "Ministry of ketchup", "superadmin", ""], csv_data[1]
    assert_equal ["Bill", "bill@bill.com", "Ministry of chips", "normal", "2000-01-01 00:00:00 +0000"], csv_data[2]
    assert_equal ["Mary", "mary@mary.com", "Ministry of brown sauce", "admin", ""], csv_data[3]
  end
end
