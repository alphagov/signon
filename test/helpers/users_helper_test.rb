require "test_helper"

class UsersHelperTest < ActionView::TestCase
  test "sync_needed? should work with user permissions not synced yet" do
    application = create(:application)
    user = create(:user)
    user.grant_application_permission(application, "signin")

    assert_nothing_raised { sync_needed?(user.application_permissions) }
  end
end
