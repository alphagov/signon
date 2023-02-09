require "test_helper"

class TwoStepVerificationExemptionsControllerTest < ActionController::TestCase
  setup do
    @gds = create(:organisation, content_id: Organisation::GDS_ORG_CONTENT_ID)
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

  def exemption_expiry_date_params(date)
    {
      "expiry_date_for_2sv_exemption(1i)" => date.year,
      "expiry_date_for_2sv_exemption(2i)" => date.month,
      "expiry_date_for_2sv_exemption(3i)" => date.day,
    }
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
        expiry_date_params = exemption_expiry_date_params(exemption_expiry_date)

        put :update, params: { id: user.id, user: { reason_for_2sv_exemption: reason_for_exemption }.merge(expiry_date_params) }

        assert_redirected_to edit_user_path(user)
        assert_user_has_been_exempted_from_2sv(user, reason_for_exemption, exemption_expiry_date)
      end
    end

    users_without_exemption_permissions = %i[super_org_admin organisation_admin user]

    users_without_exemption_permissions.each do |user_type_without_exemption_permission|
      should "not be able to exempt a user when a #{user_type_without_exemption_permission}" do
        user = create(:two_step_enabled_user, organisation: create(:organisation))
        super_org_admin = create(user_type_without_exemption_permission, organisation: @gds)
        sign_in super_org_admin
        expiry_date_params = exemption_expiry_date_params(Time.zone.today + 10)

        put :update, params: { id: user.id, user: { reason_for_2sv_exemption: @reason_for_exemption }.merge(expiry_date_params) }

        assert_user_has_not_been_exempted_from_2sv(user)
      end
    end

    context "when user parameters are invalid" do
      setup do
        super_admin = create(:superadmin_user, organisation: @gds)
        sign_in super_admin
      end

      should "not update exemption when a reason is not provided" do
        user = create(:two_step_mandated_user, organisation: create(:organisation))
        expiry_date_params = exemption_expiry_date_params(Time.zone.today + 10)
        put :update, params: { id: user.id, user: { reason_for_2sv_exemption: "" }.merge(expiry_date_params) }

        assert_redirected_to edit_two_step_verification_exemption_path(user)
        assert_equal "Reason for exemption must be provided", flash[:alert]
        assert_user_has_not_been_exempted_from_2sv(user)
      end

      should "not be able to exempt a user if the date is not in the future" do
        user = create(:two_step_mandated_user, organisation: create(:organisation))
        expiry_date_params = exemption_expiry_date_params(Time.zone.today - 1)

        put :update, params: { id: user.id, user: { reason_for_2sv_exemption: "accessibility reasons" }.merge(expiry_date_params) }

        assert_redirected_to edit_two_step_verification_exemption_path(user)
        assert_equal "Expiry date must be in the future", flash[:alert]
        assert_user_has_not_been_exempted_from_2sv(user)
      end

      should "not be able to exempt a user if the date is not valid" do
        user = create(:two_step_enabled_user, organisation: create(:organisation))

        expiry_date_params = {
          "expiry_date_for_2sv_exemption(1i)" => (Time.zone.today.year + 1).to_s,
          "expiry_date_for_2sv_exemption(2i)" => "2",
          "expiry_date_for_2sv_exemption(3i)" => "31",
        }

        put :update, params: { id: user.id, user: { reason_for_2sv_exemption: "accessibility reasons" }.merge(expiry_date_params) }

        assert_redirected_to edit_two_step_verification_exemption_path(user)
        assert_equal "Expiry date is not a valid date", flash[:alert]
        assert_user_has_not_been_exempted_from_2sv(user)
      end

      should "not be able to exempt a user if any of the date params are missing" do
        user = create(:two_step_enabled_user, organisation: create(:organisation))

        expiry_date_params = {
          "expiry_date_for_2sv_exemption(1i)" => (Time.zone.today.year + 1).to_s,
          "expiry_date_for_2sv_exemption(2i)" => "2",
          "expiry_date_for_2sv_exemption(3i)" => "31",
        }

        %w[(1i) (2i) (3i)].each do |param_suffix_to_exclude|
          param_to_exclude = "expiry_date_for_2sv_exemption#{param_suffix_to_exclude}"
          date_params = expiry_date_params.except(param_to_exclude)

          put :update, params: { id: user.id, user: { reason_for_2sv_exemption: "accessibility reasons" }.merge(date_params) }

          assert_redirected_to edit_two_step_verification_exemption_path(user)
          assert_equal "Expiry date is not a valid date", flash[:alert]
          assert_user_has_not_been_exempted_from_2sv(user)
        end
      end
    end

    should "not be able to exempt an admin user" do
      user = create(:organisation_admin, organisation: create(:organisation))
      admin = create(:superadmin_user, organisation: @gds)
      sign_in admin
      reason_for_exemption = "accessibility reasons"
      expiry_date_params = exemption_expiry_date_params(Time.zone.today + 10)

      put :update, params: { id: user.id, user: { reason_for_2sv_exemption: reason_for_exemption }.merge(expiry_date_params) }

      assert_equal "You do not have permission to perform this action.", flash[:alert]
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
        expiry_date_params = exemption_expiry_date_params(Time.zone.today + 10)

        put :update, params: { id: user.id, user: { reason_for_2sv_exemption: @reason_for_exemption }.merge(expiry_date_params) }

        assert_user_has_not_been_exempted_from_2sv(user)
      end
    end
  end
end
