require 'test_helper'

class SuspensionsControllerTest < ActionController::TestCase
  context "organisation admin" do
    should "be unable to control suspension of a user outside their organisation" do
      user = create(:suspended_user, reason_for_suspension: "Negligence")
      organisation_admin = create(:organisation_admin)
      sign_in organisation_admin

      put :update, params: { id: user.id, user: { suspended: "0" } }

      assert user.reload.suspended?
    end

    should "be able to control suspension of a user within their organisation" do
      organisation_admin = create(:organisation_admin)
      sign_in organisation_admin
      user = create(:suspended_user, reason_for_suspension: "Negligence", organisation: organisation_admin.organisation)

      put :update, params: { id: user.id, user: { suspended: "0" } }

      refute user.reload.suspended?
    end
  end

  context "super organisation admin" do
    should "be unable to control suspension of a user outside their organisation subtree" do
      user = create(:suspended_user, reason_for_suspension: "Negligence")
      super_org_admin = create(:super_org_admin)
      sign_in super_org_admin

      put :update, params: { id: user.id, user: { suspended: "0" } }

      assert user.reload.suspended?
    end

    should "be able to control suspension of a user within their organisation" do
      super_org_admin = create(:super_org_admin)
      sign_in super_org_admin
      user = create(:suspended_user, reason_for_suspension: "Negligence", organisation: super_org_admin.organisation)

      put :update, params: { id: user.id, user: { suspended: "0" } }

      refute user.reload.suspended?
    end

    should "be able to control suspension of a user within child organisations" do
      super_org_admin = create(:super_org_admin)
      child_org = create(:organisation, parent: super_org_admin.organisation)

      sign_in super_org_admin
      user = create(:suspended_user, reason_for_suspension: "Negligence", organisation: child_org)

      put :update, params: { id: user.id, user: { suspended: "0" } }

      refute user.reload.suspended?
    end
  end

  context "PUT update" do
    setup do
      user = create(:admin_user)
      sign_in user
    end

    should "be able to suspend the user and redirect to user's edit page" do
      another_user = create(:user)
      put :update, params: { id: another_user.id, user: { suspended: "1", reason_for_suspension: "Negligence" } }

      another_user.reload

      assert_redirected_to edit_user_path(another_user)
      assert_equal true, another_user.suspended?
      assert_equal "Negligence", another_user.reason_for_suspension
    end

    should "trigger permissions to be updated on downstream apps" do
      another_user = create(:user)
      PermissionUpdater.expects(:perform_on).with(another_user)

      put :update, params: { id: another_user.id, user: { suspended: "1", reason_for_suspension: "Negligence" } }
    end

    should "enforce reauth on downstream apps" do
      another_user = create(:user)
      ReauthEnforcer.expects(:perform_on).with(another_user)

      put :update, params: { id: another_user.id, user: { suspended: "1", reason_for_suspension: "Negligence" } }
    end

    should "redisplay the form if the reason is blank" do
      another_user = create(:user)
      put :update, params: { id: another_user.id, user: { suspended: "1", reason_for_suspension: "" } }
      assert_template :edit
    end

    should "be able to unsuspend the user" do
      another_user = create(:user, suspended_at: 2.months.ago, reason_for_suspension: "Text left in the box")
      put :update, params: { id: another_user.id, user: { reason_for_suspension: "Text left in the box" } }

      another_user.reload

      assert_equal false, another_user.suspended?
      assert_equal nil, another_user.reason_for_suspension
    end
  end

  context "superadmin" do
    should "suspend an api_user and redirect to api user's edit page" do
      superadmin = create(:superadmin_user)
      sign_in superadmin

      api_user = create(:api_user)
      put :update, params: { id: api_user.id, user: { suspended: "1", reason_for_suspension: "Negligence" } }

      api_user.reload

      assert_redirected_to edit_api_user_path(api_user)
      assert_equal true, api_user.suspended?
      assert_equal "Negligence", api_user.reason_for_suspension
    end
  end
end
