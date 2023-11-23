require "test_helper"

class Users::TwoStepVerificationMandationsControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  context "GET edit" do
    context "signed in as Admin user" do
      setup do
        @admin = create(:admin_user)
        sign_in(@admin)
      end

      should "display form with submit button & cancel link" do
        user = create(:user)

        get :edit, params: { user_id: user }

        assert_template :edit
        assert_select "form[action='#{user_two_step_verification_mandation_path(user)}']" do
          assert_select "button[type='submit']", text: "Mandate 2-step verification"
          assert_select "a[href='#{edit_user_path(user)}']", text: "Cancel"
        end
      end

      should "authorize access if UserPolicy#mandate_2sv? returns true" do
        user = create(:user, require_2sv: false)

        user_policy = stub_everything("user-policy", mandate_2sv?: true)
        UserPolicy.stubs(:new).returns(user_policy)

        get :edit, params: { user_id: user }

        assert_template :edit
      end

      should "not authorize access if UserPolicy#mandate_2sv? returns false" do
        user = create(:user, require_2sv: false)

        user_policy = stub_everything("user-policy", mandate_2sv?: false)
        UserPolicy.stubs(:new).returns(user_policy)

        get :edit, params: { user_id: user }

        assert_not_authorised
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

      should "mandate 2SV for user" do
        user = create(:user, require_2sv: false)

        put :update, params: { user_id: user, user: { require_2sv: true } }

        assert user.reload.require_2sv?
      end

      should "record account updated & 2SV mandated events" do
        user = create(:user, require_2sv: false)

        @controller.stubs(:user_ip_address).returns("1.1.1.1")

        EventLog.expects(:record_event).with(
          user,
          EventLog::ACCOUNT_UPDATED,
          initiator: @admin,
          ip_address: "1.1.1.1",
        )

        EventLog.expects(:record_event).with(
          user,
          EventLog::TWO_STEP_MANDATED,
          initiator: @admin,
          ip_address: "1.1.1.1",
        )

        put :update, params: { user_id: user, user: { require_2sv: true } }
      end

      should "should send email notifying user that 2SV has been mandated" do
        user = create(:user, require_2sv: false)

        perform_enqueued_jobs do
          put :update, params: { user_id: user, user: { require_2sv: true } }
        end

        email = ActionMailer::Base.deliveries.last
        assert email.present?
        assert_equal "Make your Signon account more secure", email.subject
      end

      should "push changes out to apps" do
        user = create(:user, require_2sv: false)
        PermissionUpdater.expects(:perform_on).with(user).once

        put :update, params: { user_id: user, user: { require_2sv: true } }
      end

      should "redirect to user page and display success notice" do
        user = create(:user, require_2sv: false, email: "user@gov.uk")

        put :update, params: { user_id: user, user: { require_2sv: true } }

        assert_redirected_to edit_user_path(user)
        assert_equal "Updated user user@gov.uk successfully", flash[:notice]
      end

      should "mandate 2SV for user if UserPolicy#mandate_2sv? returns true" do
        user = create(:user, require_2sv: false)

        user_policy = stub_everything("user-policy", mandate_2sv?: true)
        UserPolicy.stubs(:new).returns(user_policy)

        put :update, params: { user_id: user, user: { require_2sv: true } }

        assert user.reload.require_2sv?
      end

      should "not mandate 2SV for user if UserPolicy#mandate_2sv? returns false" do
        user = create(:user, require_2sv: false)

        user_policy = stub_everything("user-policy", mandate_2sv?: false)
        UserPolicy.stubs(:new).returns(user_policy)

        put :update, params: { user_id: user, user: { require_2sv: true } }

        assert_not user.reload.require_2sv?
        assert_not_authorised
      end

      should "display errors if user is not valid" do
        user = User.new(id: 123)
        user.errors.add(:require_2sv, "is not valid")

        User.stubs(:find).returns(user)
        UserUpdate.stubs(:new).returns(stub("user-update", call: false))

        put :update, params: { user_id: user, user: { require_2sv: true } }

        assert_select ".govuk-error-summary" do
          assert_select "a", href: "#user_require_2sv", text: "Require 2sv is not valid"
        end
      end
    end

    context "signed in as Normal user" do
      setup do
        sign_in(create(:user))
      end

      should "not be authorized" do
        user = create(:user)

        put :update, params: { user_id: user }

        assert_not_authorised
      end
    end

    context "not signed in" do
      should "not be allowed access" do
        user = create(:user)

        put :update, params: { user_id: user }

        assert_not_authenticated
      end
    end
  end
end
