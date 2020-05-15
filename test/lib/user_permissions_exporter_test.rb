require "test_helper"

class UserPermissionsExporterTest < ActionView::TestCase
  def setup
    @chips_org = create(:organisation, name: "Ministry of chips")
    @ketchup_org = create(:organisation, name: "Ministry of ketchup")
    @brown_sauce_org = create(:organisation, name: "Ministry of brown sauce")
    @bill = create(
      :user,
      name: "Bill",
      email: "bill@bill.com",
      organisation: @chips_org,
      suspended_at: Date.parse("2000-01-01"),
      reason_for_suspension: "Left Chips.org",
    )
    @anne = create(:user, name: "Anne", email: "anne@anne.com", role: "superadmin", organisation: @ketchup_org)
    @mary = create(:user, name: "Mary", email: "mary@mary.com", role: "admin", organisation: @brown_sauce_org)

    @tmpfile = Tempfile.new(%w[user_permissions_exporter_test_example csv])
    UserPermissionsExporter.any_instance.stubs(:file_path).returns(@tmpfile.path)
    UserPermissionsExporter.any_instance.stubs(:signon_file_path).returns(@tmpfile.path)
  end

  def test_export_one_application
    foo_app = create(:application, name: "Foo", with_supported_permissions: %w[administer add_vinegar do_some_stuff cook])
    @bill.grant_application_permissions(foo_app, %w[signin cook])
    @anne.grant_application_permissions(foo_app, %w[signin administer add_vinegar])
    @mary.grant_application_permissions(foo_app, %w[signin do_some_stuff])

    UserPermissionsExporter.new(@tmpfile.path).export(%w[Foo])

    csv_data = CSV.read(@tmpfile.path)

    assert_equal %w[Name Email Organisation Permissions],                                     csv_data[0]
    assert_equal %w[Anne anne@anne.com Ministry\ of\ ketchup add_vinegar,administer,signin],  csv_data[1]
    assert_equal %w[Bill bill@bill.com Ministry\ of\ chips cook,signin],                      csv_data[2]
    assert_equal %w[Mary mary@mary.com Ministry\ of\ brown\ sauce do_some_stuff,signin],      csv_data[3]
  end

  def test_export_multiple_applications
    foo_app = create(:application, name: "Foo", with_supported_permissions: %w[administer add_vinegar do_some_stuff cook])
    bar_app = create(:application, name: "Bar", with_supported_permissions: %w[administer])
    baz_app = create(:application, name: "Baz")

    @bill.grant_application_permissions(foo_app, %w[signin cook])
    @bill.grant_application_permissions(baz_app, [])
    @anne.grant_application_permissions(foo_app, %w[signin administer add_vinegar])
    @anne.grant_application_permissions(bar_app, %w[signin administer])
    @mary.grant_application_permissions(foo_app, %w[signin do_some_stuff])
    @mary.grant_application_permissions(bar_app, %w[signin administer])

    UserPermissionsExporter.new(@tmpfile.path).export(%w[Foo Bar Baz])

    csv_data = CSV.read(@tmpfile.path)

    assert_equal %w[Application Name Email Organisation Permissions],                             csv_data[0]
    assert_equal %w[Bar Anne anne@anne.com Ministry\ of\ ketchup administer,signin],              csv_data[1]
    assert_equal %w[Bar Mary mary@mary.com Ministry\ of\ brown\ sauce administer,signin],         csv_data[2]
    assert_equal %w[Foo Anne anne@anne.com Ministry\ of\ ketchup add_vinegar,administer,signin],  csv_data[3]
    assert_equal %w[Foo Bill bill@bill.com Ministry\ of\ chips cook,signin],                      csv_data[4]
    assert_equal %w[Foo Mary mary@mary.com Ministry\ of\ brown\ sauce do_some_stuff,signin],      csv_data[5]
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
