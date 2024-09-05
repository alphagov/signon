require "test_helper"

class TwoStepVerificationExemptionsControllerTest < ActionController::TestCase
  setup do
    @gds = create(:gds_organisation)
    @organisation = create(:organisation)
  end

  def assert_user_has_been_exempted_from_2sv(user, reason, expiry_date = nil)
    user.reload

    assert_not user.require_2sv?
    assert_equal reason, user.reason_for_2sv_exemption
    assert_equal expiry_date, user.expiry_date_for_2sv_exemption
    assert_nil user.otp_secret_key
  end

  def assert_user_has_not_been_exempted_from_2sv(user)
    previous_require_2sv = user.require_2sv?
    previous_secret_key = user.otp_secret_key

    user.reload

    assert_equal previous_require_2sv, user.require_2sv?
    assert_nil user.reason_for_2sv_exemption
    assert_nil user.expiry_date_for_2sv_exemption
    # Annoyingly, we can't use assert_equals here as it throws a deprecation warning to use assert_nil when previous_secret_key is nil
    assert previous_secret_key == user.otp_secret_key
  end

  def date_params(date)
    { day: date.day, month: date.month, year: date.year }
  end

  context "gds admins" do
    admins_with_exemption_permissions = %i[superadmin_user admin_user]

    admins_with_exemption_permissions.each do |admin_type_with_exemption_permission|
      should "be able to exempt a user from any organisation when a #{admin_type_with_exemption_permission}" do
        user = create(:user, organisation: create(:organisation))
        admin = create(admin_type_with_exemption_permission, organisation: @gds)
        sign_in admin
        reason_for_exemption = "accessibility reasons"
        exemption_expiry_date = Time.zone.today + 10
        expiry_date_params = date_params(exemption_expiry_date)

        put :update, params: { id: user.id, exemption: { reason: reason_for_exemption, expiry_date: expiry_date_params } }

        assert_redirected_to edit_user_path(user)
        assert_user_has_been_exempted_from_2sv(user, reason_for_exemption, exemption_expiry_date)
      end
    end

    users_without_exemption_permissions = %i[super_organisation_admin_user organisation_admin_user user]

    users_without_exemption_permissions.each do |user_type_without_exemption_permission|
      should "not be able to exempt a user when a #{user_type_without_exemption_permission}" do
        user = create(:two_step_enabled_user, organisation: create(:organisation))
        super_org_admin = create(user_type_without_exemption_permission, organisation: @gds)
        sign_in super_org_admin
        expiry_date_params = date_params(Time.zone.today + 10)

        put :update, params: { id: user.id, exemption: { reason: @reason_for_exemption, expiry_date: expiry_date_params } }

        assert_user_has_not_been_exempted_from_2sv(user)
      end
    end

    should "not update exemption when parameters are invalid" do
      user = create(:two_step_mandated_user, organisation: create(:organisation))
      super_admin = create(:superadmin_user, organisation: @gds)
      sign_in super_admin
      date_params(Time.zone.today + 10)

      put :update, params: { id: user.id, exemption: { reason: "", expiry_date: { day: "", month: "", year: "" } } }

      exemption = assigns[:exemption]
      assert_not exemption.valid?
      assert_includes exemption.errors[:reason], "must be provided"
      assert_includes exemption.errors[:expiry_date], "must be provided"
      assert_user_has_not_been_exempted_from_2sv(user)
    end

    should "not be able to exempt an admin user" do
      user = create(:organisation_admin_user, organisation: create(:organisation))
      admin = create(:superadmin_user, organisation: @gds)
      sign_in admin
      reason_for_exemption = "accessibility reasons"
      expiry_date_params = date_params(Time.zone.today + 10)

      put :update, params: { id: user.id, exemption: { reason: reason_for_exemption, expiry_date: expiry_date_params } }

      assert_not_authorised
      assert_nil user.reason_for_2sv_exemption
    end
  end

  context "non-gds users" do
    user_types = %i[superadmin_user admin_user super_organisation_admin_user organisation_admin_user user]

    user_types.each do |user_type|
      should "not be able to exempt a user from any organisation when logged in as a non-gds #{user_type}" do
        user = create(:two_step_enabled_user, organisation: @organisation)
        logged_in_as_user = create(user_type, organisation: @organisation)
        sign_in logged_in_as_user
        expiry_date_params = date_params(Time.zone.today + 10)

        put :update, params: { id: user.id, exemption: { reason: @reason_for_exemption, expiry_date: expiry_date_params } }

        assert_user_has_not_been_exempted_from_2sv(user)
      end
    end
  end
end
