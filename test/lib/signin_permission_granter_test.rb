require "test_helper"

class SigninPermissionGranterTest < ActiveSupport::TestCase
  setup do
    @application_supporting_push_updates = create(:application, supports_push_updates: true)
    @application_not_supporting_push_updates = create(:application, supports_push_updates: false)
    $stdout.stubs(:puts)
  end

  should "update users who do not have permission and update the application if it supports push updates" do
    first_user = create(:user)
    second_user = create(:user)
    user_with_permission = create(:user, with_signin_permissions_for: [@application_supporting_push_updates])
    first_user.expects(:grant_application_signin_permission).with(@application_supporting_push_updates).once
    second_user.expects(:grant_application_signin_permission).with(@application_supporting_push_updates).once
    PermissionUpdater.expects(:perform_later).with(anything, @application_supporting_push_updates.id).twice

    user_with_permission.expects(:grant_application_permission).never

    SigninPermissionGranter.call(users: [first_user, second_user, user_with_permission], application: @application_supporting_push_updates)
  end

  should "not send a push update to an application with updated users if the application does not support it" do
    user = create(:user)

    user.expects(:grant_application_signin_permission).with(@application_not_supporting_push_updates).once
    PermissionUpdater.expects(:perform_later).with(user.id, @application_not_supporting_push_updates.id).never

    SigninPermissionGranter.call(users: [user], application: @application_not_supporting_push_updates)
  end
end
