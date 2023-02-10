require "test_helper"

class UserExportPresenterTest < ActiveSupport::TestCase
  def setup
    Timecop.freeze(2015, 1, 15, 9, 0)
    @apps = 5.times.map { |i| create(:application, name: "App #{i}") }
    @user = create(:two_step_enabled_user, name: "Test User", email: "test@dept.gov.uk")
    create(:supported_permission, application: @apps[0], name: "editor")
    create(:supported_permission, application: @apps[2], name: "editor")
    create(:supported_permission, application: @apps[2], name: "admin")
  end

  should "output header row including application names" do
    header_row = UserExportPresenter.new(@apps).header_row

    expected = [
      "Name",
      "Email",
      "Role",
      "Organisation",
      "Sign-in count",
      "Last sign-in",
      "Created",
      "Status",
      "2SV Status",
      "2SV Exemption Expiry Date",
      "App 0",
      "App 1",
      "App 2",
      "App 3",
      "App 4",
    ]
    assert_equal(expected, header_row)
  end

  should "include sorted permissions for each application" do
    @user.grant_application_permissions(@apps[0], %w[editor])
    @user.grant_application_permissions(@apps[2], %w[editor admin])

    perms = UserExportPresenter.new(@apps).app_permissions_for(@user)

    expected = ["editor", nil, "admin, editor", nil, nil]
    assert_equal(expected, perms)
  end

  should "output user details" do
    row = UserExportPresenter.new([]).row(@user)
    expected = [
      "Test User", "test@dept.gov.uk", "Normal", nil, 0, nil, "2015-01-15 09:00:00", "Active", "Enabled", nil
    ]
    assert_equal(expected, row)
  end

  should "include exemption date for an exempted user" do
    exemption_date = (Time.zone.today + 1).to_date
    user = create(:two_step_exempted_user, name: "Exempted User", email: "exempted@dept.gov.uk", expiry_date_for_2sv_exemption: exemption_date)
    row = UserExportPresenter.new([]).row(user)
    expected = [
      "Exempted User", "exempted@dept.gov.uk", "Normal", nil, 0, nil, "2015-01-15 09:00:00", "Active", "Exempted", exemption_date.strftime("%d/%m/%Y")
    ]
    assert_equal(expected, row)
  end
end
