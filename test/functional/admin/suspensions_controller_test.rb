require 'test_helper'

class Admin::SuspensionsControllerTest < ActionController::TestCase

  context "organisation admin" do
    should "be unable to control suspension of a user outside their organisation" do
      user = create(:suspended_user, reason_for_suspension: "Negligence")
      admin = create(:organisation_admin)
      sign_in admin

      put :update, id: user.id, user: { suspended: "0" }

      assert_true user.reload.suspended?
    end

    should "be able to control suspension of a user within their organisation" do
      admin = create(:organisation_admin)
      sign_in admin
      user = create(:suspended_user, reason_for_suspension: "Negligence", organisation: admin.organisation)

      put :update, id: user.id, user: { suspended: "0" }

      assert_false user.reload.suspended?
    end
  end

  setup do
    user = create(:admin_user)
    sign_in user
  end

  context "PUT update" do
    should "be able to suspend the user" do
      another_user = create(:user)
      put :update, id: another_user.id, user: { suspended: "1", reason_for_suspension: "Negligence" }

      another_user.reload

      assert_equal true, another_user.suspended?
      assert_equal "Negligence", another_user.reason_for_suspension
    end

    should "enforce reauth on downstream apps" do
      another_user = create(:user)
      ReauthEnforcer.expects(:perform_on).with(another_user)

      put :update, id: another_user.id, user: { suspended: "1", reason_for_suspension: "Negligence" }
    end

    should "redisplay the form if the reason is blank" do
      another_user = create(:user)
      put :update, id: another_user.id, user: { suspended: "1", reason_for_suspension: "" }
      assert_template :edit
    end

    should "be able to unsuspend the user" do
      another_user = create(:user, suspended_at: 2.months.ago, reason_for_suspension: "Text left in the box")
      put :update, id: another_user.id, user: { reason_for_suspension: "Text left in the box" }

      another_user.reload

      assert_equal false, another_user.suspended?
      assert_equal nil, another_user.reason_for_suspension
    end
  end
end
