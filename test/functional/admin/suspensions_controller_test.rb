require 'test_helper'

class Admin::SuspensionsControllerTest < ActionController::TestCase

  setup do
    @user = FactoryGirl.create(:user, is_admin: true)
    sign_in @user
  end

  context "PUT update" do
    should "be able to suspend the user" do
      PropagateSuspension.any_instance.stubs(:attempt).returns({})
      another_user = FactoryGirl.create(:user)
      put :update, id: another_user.id, user: { suspended: "1", reason_for_suspension: "Negligence" }

      another_user.reload

      assert_equal true, another_user.suspended?
      assert_equal "Negligence", another_user.reason_for_suspension
    end

    should "push suspension out to the apps" do
      another_user = FactoryGirl.create(:user)
      app = FactoryGirl.create(:application)

      PropagateSuspension.expects(:new).with(another_user, [app]).returns(mock("suspenders", attempt: {}))

      put :update, id: another_user.id, user: { suspended: "1", reason_for_suspension: "Negligence" }

      assert_equal 200, response.status
    end

    should "be able to unsuspend the user" do
      another_user = FactoryGirl.create(:user, suspended_at: 2.months.ago, reason_for_suspension: "Text left in the box")
      put :update, id: another_user.id, user: { reason_for_suspension: "Text left in the box" }

      another_user.reload

      assert_equal false, another_user.suspended?
      assert_equal nil, another_user.reason_for_suspension
      assert_redirected_to admin_users_path
    end
  end
end
