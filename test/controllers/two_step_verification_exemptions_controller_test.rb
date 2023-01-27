require "test_helper"

class TwoStepVerificationExemptionsControllerTest < ActionController::TestCase
  setup do
    @gds = create(:organisation, content_id: Organisation::GDS_ORG_CONTENT_ID)
    @organisation = create(:organisation)
  end

  def assert_user_has_been_exempted_from_2sv(user, reason)
    user.reload

    assert_not user.require_2sv?
    assert_equal reason, user.reason_for_2sv_exemption
    assert_nil user.otp_secret_key
  end

  def assert_user_has_not_been_exempted_from_2sv(user)
    user.reload

    assert user.require_2sv?
    assert_nil user.reason_for_2sv_exemption
    assert user.otp_secret_key.present?
  end

  context "gds admins" do
    admins_with_exemption_permissions = %i[superadmin_user admin_user]

    admins_with_exemption_permissions.each do |admin_type_with_exemption_permission|
      should "be able to exempt a user from any organisation when a #{admin_type_with_exemption_permission}" do
        user = create(:user, organisation: create(:organisation))
        admin = create(admin_type_with_exemption_permission, organisation: @gds)
        sign_in admin
        reason_for_exemption = "accessibility reasons"

        put :update, params: { id: user.id, user: { reason_for_2sv_exemption: reason_for_exemption } }

        assert_redirected_to edit_user_path(user)
        assert_user_has_been_exempted_from_2sv(user, reason_for_exemption)
      end
    end

    users_without_exemption_permissions = %i[super_org_admin organisation_admin user]

    users_without_exemption_permissions.each do |user_type_without_exemption_permission|
      should "not be able to exempt a user when a #{user_type_without_exemption_permission}" do
        user = create(:two_step_enabled_user, organisation: create(:organisation))
        super_org_admin = create(user_type_without_exemption_permission, organisation: @gds)
        sign_in super_org_admin

        put :update, params: { id: user.id, user: { reason_for_2sv_exemption: @reason_for_exemption } }

        assert_user_has_not_been_exempted_from_2sv(user)
      end
    end

    should "not update exemption when a reason is not provided" do
      user = create(:two_step_mandated_user, organisation: create(:organisation))
      super_admin = create(:superadmin_user, organisation: @gds)
      sign_in super_admin
      put :update, params: { id: user.id, user: { reason_for_2sv_exemption: "" } }

      user.reload

      assert_redirected_to edit_two_step_verification_exemption_path(user)
      assert user.require_2sv?
      assert_nil user.reason_for_2sv_exemption
    end
  end

  context "non-gds users" do
    user_types = %i[superadmin_user admin_user super_org_admin organisation_admin user]

    user_types.each do |user_type|
      should "not be able to exempt a user from any organisation when logged in as a non-gds #{user_type}" do
        user = create(:two_step_enabled_user, organisation: @organisation)
        logged_in_as_user = create(user_type, organisation: @organisation)
        sign_in logged_in_as_user
        put :update, params: { id: user.id, user: { reason_for_2sv_exemption: @reason_for_exemption } }

        assert_user_has_not_been_exempted_from_2sv(user)
      end
    end
  end
end
