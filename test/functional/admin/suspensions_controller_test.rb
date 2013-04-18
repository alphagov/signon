require 'test_helper'

class Admin::SuspensionsControllerTest < ActionController::TestCase

  setup do
    @user = FactoryGirl.create(:user, role: "admin")
    sign_in @user
  end

  context "PUT update" do
    should "be able to suspend the user" do
      SuspensionUpdater.any_instance.stubs(:attempt).returns({})
      another_user = FactoryGirl.create(:user)
      put :update, id: another_user.id, user: { suspended: "1", reason_for_suspension: "Negligence" }

      another_user.reload

      assert_equal true, another_user.suspended?
      assert_equal "Negligence", another_user.reason_for_suspension
    end

    should "redisplay the form if the reason is blank" do
      another_user = FactoryGirl.create(:user)
      put :update, id: another_user.id, user: { suspended: "1", reason_for_suspension: "" }
      assert_template :edit
    end

    should "push suspension out to the apps (but only those ever used by them)" do
      another_user = FactoryGirl.create(:user)
      app = FactoryGirl.create(:application)
      unused_app = FactoryGirl.create(:application)
      # simulate them having used (and 'authorized' the app)
      ::Doorkeeper::AccessToken.create(resource_owner_id: another_user.id, application_id: app.id, token: "1234")


      SuspensionUpdater.expects(:new).with(another_user, [app]).returns(mock("suspenders", attempt: {}))

      put :update, id: another_user.id, user: { suspended: "1", reason_for_suspension: "Negligence" }

      assert_equal 200, response.status
    end

    should "be able to unsuspend the user" do
      another_user = FactoryGirl.create(:user, suspended_at: 2.months.ago, reason_for_suspension: "Text left in the box")
      put :update, id: another_user.id, user: { reason_for_suspension: "Text left in the box" }

      another_user.reload

      assert_equal false, another_user.suspended?
      assert_equal nil, another_user.reason_for_suspension
    end
  end
end
