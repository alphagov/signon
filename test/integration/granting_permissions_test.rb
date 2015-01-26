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

    permission = Permission.where(application_id: app.id, user_id: @user.id).first
    assert_equal ["signin"], permission.permissions
  end

  should "support granting app-specific permissions" do
    app = create(:application, name: "MyApp", with_supported_permissions: ["write"])

    visit edit_user_path(@user)
    select "write", from: "Permissions for MyApp"
    click_button "Update User"

    permission = Permission.where(application_id: app.id, user_id: @user.id).first
    assert_equal ["write"], permission.permissions
  end

  should "allow the admin to note key events for that user, such as training" do
    app = create(:application, name: "MyApp", with_supported_permissions: ["write"])

    visit edit_user_path(@user)
    select "write", from: "Permissions for MyApp"

    within ".new-note" do
      fill_in "Details", with: "Completed author training"
      select "Training", from: "Type"
      fill_in "Occurred on", with: "2014-11-22"
    end

    click_button "Update User"

    assert_equal 1, @user.notes.count

    last_note = @user.notes.last
    assert_equal "Completed author training", last_note.details
    assert_equal "training", last_note.type
    assert_equal "2014-11-22", last_note.occurred_on.strftime("%F")
  end
end
