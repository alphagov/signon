require "test_helper"

class Users::TwoStepVerificationResetsControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper

  context "GET edit" do
    context "signed in as Admin user" do
      setup do
        @admin = create(:admin_user)
        sign_in(@admin)
      end

      should "display form with submit button & cancel link" do
        user = create(:two_step_enabled_user)

        get :edit, params: { user_id: user }

        assert_template :edit
        assert_select "form[action='#{user_two_step_verification_reset_path(user)}']" do
          assert_select "button[type='submit']", text: "Reset 2-step verification"
          assert_select "a[href='#{edit_user_path(user)}']", text: "Cancel"
        end
      end

      should "authorize access if UserPolicy#reset_2sv? returns true" do
        user = create(:two_step_enabled_user)

        stub_policy(@admin, user, reset_2sv?: true)
        stub_policy_for_navigation_links(@admin)

        get :edit, params: { user_id: user }

        assert_template :edit
      end

      should "not authorize access if UserPolicy#reset_2sv? returns false" do
        user = create(:two_step_enabled_user)

        stub_policy(@admin, user, reset_2sv?: false)
        stub_policy_for_navigation_links(@admin)

        get :edit, params: { user_id: user }

        assert_not_authorised
      end

      should "redirect to account change 2-step verification phone page if admin is acting on their own user" do
        get :edit, params: { user_id: @admin }

        assert_redirected_to two_step_verification_path
      end
    end

    context "signed in as Normal user" do
      setup do
        sign_in(create(:user))
      end

      should "not be authorized" do
        user = create(:user)

        get :edit, params: { user_id: user }

        assert_not_authorised
      end
    end

    context "not signed in" do
      should "not be allowed access" do
        user = create(:user)

        get :edit, params: { user_id: user }

        assert_not_authenticated
      end
    end
  end

  context "PUT update" do
    context "signed in as Admin user" do
      setup do
        @admin = create(:admin_user)
        sign_in(@admin)
      end

      should "reset 2SV for user" do
        user = create(:two_step_enabled_user)

        put :update, params: { user_id: user }

        user.reload
        assert user.otp_secret_key.blank?
        assert user.require_2sv?
      end

      should "record account updated event" do
        user = create(:two_step_enabled_user)

        EventLog.stubs(:record_event).with(user, EventLog::ACCOUNT_UPDATED, anything)
        EventLog.expects(:record_event).with(user, EventLog::TWO_STEP_RESET, initiator: true)

        put :update, params: { user_id: user }
      end

      should "should send email notifying user that their 2SV has been reset" do
        user = create(:two_step_enabled_user)

        perform_enqueued_jobs do
          put :update, params: { user_id: user }
        end

        email = ActionMailer::Base.deliveries.last
        assert email.present?
        assert_equal "2-step verification has been reset", email.subject
      end

      should "redirect to user page and display success notice" do
        user = create(:two_step_enabled_user, email: "user@gov.uk")

        put :update, params: { user_id: user }

        assert_redirected_to edit_user_path(user)
        assert_equal "Reset 2-step verification for user@gov.uk", flash[:notice]
      end

      should "reset 2SV for user if UserPolicy#reset_2sv? returns true" do
        user = create(:two_step_enabled_user)

        stub_policy(@admin, user, reset_2sv?: true)

        put :update, params: { user_id: user }

        assert user.reload.otp_secret_key.blank?
      end

      should "not reset 2SV for user if UserPolicy#reset_2sv? returns false" do
        user = create(:two_step_enabled_user)

        stub_policy(@admin, user, reset_2sv?: false)

        put :update, params: { user_id: user }

        assert user.reload.otp_secret_key.present?
        assert_not_authorised
      end
    end

    context "signed in as Normal user" do
      setup do
        sign_in(create(:user))
      end

      should "not be authorized" do
        user = create(:two_step_enabled_user)

        put :update, params: { user_id: user }

        assert_not_authorised
      end
    end

    context "not signed in" do
      should "not be allowed access" do
        user = create(:two_step_enabled_user)

        put :update, params: { user_id: user }

        assert_not_authenticated
      end
    end
  end
end
