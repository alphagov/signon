require 'test_helper'

class GrantingPermissionsTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:superadmin_user)
    @user = create(:user)

    visit root_path
    signin(@admin)
  end

  should "support granting signin permissions" do
    app = create(:application, name: "MyApp")

    visit edit_user_path(@user)
    check "Has access to MyApp?"
    click_button "Update User"

    assert @user.has_access_to?(app)
  end

  should "support granting app-specific permissions" do
    app = create(:application, name: "MyApp", with_supported_permissions: ["write"])

    visit edit_user_path(@user)
    select "write", from: "Permissions for MyApp"
    click_button "Update User"

    assert_include @user.permissions_for(app), 'write'
  end

  should "log changed permissions" do
    app = create(:application, name: "MyApp", with_supported_permissions: ["write"])

    visit edit_user_path(@user)
    select "write", from: "Permissions for MyApp"

    click_button "Update User"

    last_log = @user.event_logs.last

    assert_equal({
      added: {
        "MyApp" => ["write"]
      },
      removed: {}
    }, last_log.data)
  end

  should "allow the admin to provide a change note" do
    app = create(:application, name: "MyApp", with_supported_permissions: ["write"])

    visit edit_user_path(@user)
    select "write", from: "Permissions for MyApp"

    within ".new-note" do
      fill_in "Add a change note (optional)", with: "Completed author training"
    end

    click_button "Update User"

    last_log = @user.event_logs.last
    assert_equal "Completed author training", last_log.trailing_message
  end
end
