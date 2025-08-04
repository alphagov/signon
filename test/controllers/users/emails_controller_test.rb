require "test_helper"

class Users::EmailsControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  context "GET edit" do
    context "signed in as Superadmin user" do
      setup do
        @superadmin = create(:superadmin_user)
        sign_in(@superadmin)
      end

      should "display breadcrumb links back to edit user page & users page for non-API user" do
        user = create(:user)

        get :edit, params: { user_id: user }

        assert_select ".govuk-breadcrumbs" do
          assert_select "a[href='#{users_path}']"
          assert_select "a[href='#{edit_user_path(user)}']"
        end
      end

      should "display breadcrumb links back to edit API user page & API users page for API user" do
        user = create(:api_user)

        get :edit, params: { api_user_id: user }

        assert_select ".govuk-breadcrumbs" do
          assert_select "a[href='#{api_users_path}']"
          assert_select "a[href='#{edit_api_user_path(user)}']"
        end
      end

      should "display form with email field & cancel link for non-API user" do
        user = create(:user, email: "user@gov.uk")

        get :edit, params: { user_id: user }

        assert_template :edit
        assert_select "form[action='#{user_email_path(user)}']" do
          assert_select "input[name='user[email]']", value: "user@gov.uk"
          assert_select "button[type='submit']", text: "Change email"
          assert_select "a[href='#{edit_user_path(user)}']", text: "Cancel"
        end
      end

      should "display form with email field & cancel link for API user" do
        user = create(:api_user, name: "user-name")

        get :edit, params: { api_user_id: user }

        assert_template :edit
        assert_select "form[action='#{api_user_email_path(user)}']" do
          assert_select "input[name='user[email]']", value: "user@gov.uk"
          assert_select "button[type='submit']", text: "Change email"
          assert_select "a[href='#{edit_api_user_path(user)}']", text: "Cancel"
        end
      end

      should "show the pending email & action links if applicable" do
        user = create(:user_with_pending_email_change)

        get :edit, params: { user_id: user }

        expected_text = /An email has been sent to #{user.unconfirmed_email} with a link to confirm the change./
        assert_select ".govuk-notification-banner", text: expected_text
        assert_select "a", href: resend_email_change_user_email_path(user), text: "Resend confirmation email"
        assert_select "a", href: cancel_email_change_user_email_path(user), text: "Cancel change"
      end

      should "authorize access if UserPolicy#edit? returns true" do
        user = create(:user)

        stub_policy(@superadmin, user, edit?: true)
        stub_policy_for_navigation_links(@superadmin)

        get :edit, params: { user_id: user }

        assert_template :edit
      end

      should "not authorize access if UserPolicy#edit? returns false" do
        user = create(:user)

        stub_policy(@superadmin, user, edit?: false)
        stub_policy_for_navigation_links(@superadmin)

        get :edit, params: { user_id: user }

        assert_not_authorised
      end

      should "authorize access if ApiUserPolicy#edit? returns true when user is an API user" do
        user = create(:api_user)

        stub_policy(@superadmin, user, edit?: true)
        stub_policy_for_navigation_links(@superadmin)

        get :edit, params: { api_user_id: user }

        assert_template :edit
      end

      should "not authorize access if ApiUserPolicy#edit? returns false when user is an API user" do
        user = create(:api_user)

        stub_policy(@superadmin, user, edit?: false)
        stub_policy_for_navigation_links(@superadmin)

        get :edit, params: { api_user_id: user }

        assert_not_authorised
      end

      should "redirect to account edit email page if admin is acting on their own user" do
        get :edit, params: { user_id: @superadmin }

        assert_redirected_to edit_account_email_path
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
    context "signed in as Superadmin user" do
      setup do
        @superadmin = create(:superadmin_user)
        sign_in(@superadmin)
      end

      should "update user email" do
        user = create(:user, email: "user@gov.uk")

        put :update, params: { user_id: user, user: { email: "new-user@gov.uk" } }

        assert_equal "new-user@gov.uk", user.reload.email
      end

      should "not reconfirm user email" do
        user = create(:user, email: "user@gov.uk")

        put :update, params: { user_id: user, user: { email: "new-user@gov.uk" } }

        assert user.reload.unconfirmed_email.blank?
      end

      should "send email change notifications to old and new email address" do
        perform_enqueued_jobs do
          user = create(:user, email: "user@gov.uk")

          put :update, params: { user_id: user, user: { email: "new-user@gov.uk" } }

          expected_subject = "Your GOV.UK Signon test email address has been updated"
          emails = ActionMailer::Base.deliveries.select { |e| e.subject = expected_subject }
          assert_equal(%w[user@gov.uk new-user@gov.uk], emails.map { |mail| mail.to.first })
        end
      end

      should "not send email change notifications if email has not changed" do
        user = create(:user, email: "user@gov.uk")

        assert_no_enqueued_emails do
          put :update, params: { user_id: user, user: { email: "user@gov.uk" } }
        end
      end

      should "not send email change notifications if user is API user" do
        user = create(:api_user, email: "user@gov.uk")

        assert_no_enqueued_emails do
          put :update, params: { api_user_id: user, user: { email: "new-user@gov.uk" } }
        end
      end

      should "also send an invitation email if user has not accepted invitation" do
        perform_enqueued_jobs do
          user = create(:invited_user, email: "user@gov.uk")

          put :update, params: { user_id: user, user: { email: "new-user@gov.uk" } }

          expected_subject = "Please confirm your account"
          invitation_email = ActionMailer::Base.deliveries.find { |e| e.subject = expected_subject }
          assert_equal "new-user@gov.uk", invitation_email.to.first
        end
      end

      should "not send an invitation email if email has not changed" do
        user = create(:invited_user, email: "user@gov.uk")

        assert_no_enqueued_emails do
          put :update, params: { user_id: user, user: { email: "user@gov.uk" } }
        end
      end

      should "not send an invitation email if API user has not accepted invitation" do
        user = create(:api_user, :invited, email: "user@gov.uk")

        assert_no_enqueued_emails do
          put :update, params: { api_user_id: user, user: { email: "new-user@gov.uk" } }
        end
      end

      should "record email change" do
        user = create(:user, email: "user@gov.uk")

        EventLog.expects(:record_email_change).with(user, "user@gov.uk", "new-user@gov.uk", @superadmin)

        put :update, params: { user_id: user, user: { email: "new-user@gov.uk" } }
      end

      should "should not record email change if email has not changed" do
        user = create(:user, email: "user@gov.uk")

        EventLog.expects(:record_email_change).never

        put :update, params: { user_id: user, user: { email: "user@gov.uk" } }
      end

      should "push changes out to apps" do
        user = create(:user)
        PermissionUpdater.expects(:perform_on).with(user)

        put :update, params: { user_id: user, user: { email: "new-user@gov.uk" } }
      end

      should "redirect to edit user page and display success notice for non-API user" do
        user = create(:user, email: "user@gov.uk")

        put :update, params: { user_id: user, user: { email: "new-user@gov.uk" } }

        assert_redirected_to edit_user_path(user)
        assert "Updated user new-user@gov.uk successfully", flash[:notice]
      end

      should "redirect to edit API user page and display success notice for API user" do
        user = create(:api_user, email: "user@gov.uk")

        put :update, params: { api_user_id: user, user: { email: "new-user@gov.uk" } }

        assert_redirected_to edit_api_user_path(user)
        assert "Updated user new-user@gov.uk successfully", flash[:notice]
      end

      should "update user email if UserPolicy#update? returns true" do
        user = create(:user, email: "user@gov.uk")

        stub_policy(@superadmin, user, update?: true)

        put :update, params: { user_id: user, user: { email: "new-user@gov.uk" } }

        assert_equal "new-user@gov.uk", user.reload.email
      end

      should "not update user email if UserPolicy#update? returns false" do
        user = create(:user, email: "user@gov.uk")

        stub_policy(@superadmin, user, update?: false)

        put :update, params: { user_id: user, user: { email: "new-user@gov.uk" } }

        assert_equal "user@gov.uk", user.reload.email
        assert_not_authorised
      end

      should "update user email if ApiUserPolicy#update? returns true when user is an API user" do
        user = create(:api_user, email: "user@gov.uk")

        stub_policy(@superadmin, user, update?: true)

        put :update, params: { api_user_id: user, user: { email: "new-user@gov.uk" } }

        assert_equal "new-user@gov.uk", user.reload.email
      end

      should "not update user email if ApiUserPolicy#update? returns false when user is an API user" do
        user = create(:api_user, email: "user@gov.uk")

        stub_policy(@superadmin, user, update?: false)

        put :update, params: { api_user_id: user, user: { email: "new-user@gov.uk" } }

        assert_equal "user@gov.uk", user.reload.email
        assert_not_authorised
      end

      should "redisplay form if email is not valid" do
        user = create(:user, email: "user@gov.uk")

        put :update, params: { user_id: user, user: { email: "" } }

        assert_template :edit
        assert_select "form[action='#{user_email_path(user)}']" do
          assert_select "input[name='user[email]']", value: ""
        end
      end

      should "display errors if email is not valid" do
        user = create(:user)

        put :update, params: { user_id: user, user: { email: "" } }

        assert_select ".govuk-error-summary" do
          assert_select "a", href: "#user_email", text: "Email can't be blank"
        end
        assert_select ".govuk-form-group" do
          assert_select ".govuk-error-message", text: "Error: Email can't be blank"
          assert_select "input[name='user[email]'].govuk-input--error"
        end
      end
    end

    context "signed in as Normal user" do
      setup do
        sign_in(create(:user))
      end

      should "not be authorized" do
        user = create(:user)

        put :update, params: { user_id: user, user: { email: "new-user@gov.uk" } }

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

  context "PUT resend_email_change" do
    context "signed in as Superadmin user" do
      setup do
        @superadmin = create(:superadmin_user)
        sign_in(@superadmin)
      end

      should "send an email change confirmation email" do
        perform_enqueued_jobs do
          user = create(:user_with_pending_email_change)

          put :resend_email_change, params: { user_id: user }

          assert_equal "Confirm changes to your GOV.UK Signon test account", ActionMailer::Base.deliveries.last.subject
        end
      end

      should "use a new token if the old one has expired" do
        user = create(
          :user_with_pending_email_change,
          :with_expired_confirmation_token,
          confirmation_token: "old-token",
        )

        put :resend_email_change, params: { user_id: user }

        assert_not_equal "old-token", user.reload.confirmation_token
      end

      should "redirect to edit user page and display success notice" do
        user = create(:user_with_pending_email_change)

        put :resend_email_change, params: { user_id: user }

        assert_redirected_to edit_user_path(user)
        assert_equal "Successfully resent email change email to #{user.unconfirmed_email}", flash[:notice]
      end

      should "redirect to edit user email page and display failure alert if resending fails" do
        user = create(:user)

        put :resend_email_change, params: { user_id: user }

        assert_redirected_to edit_user_email_path(user)
        assert_equal "Failed to send email change email", flash[:alert]
      end

      should "send an email change confirmation email if UserPolicy#resend_email_change? returns true" do
        user = create(:user_with_pending_email_change)

        stub_policy(@superadmin, user, resend_email_change?: true)

        assert_enqueued_emails 1 do
          put :resend_email_change, params: { user_id: user }
        end
        assert_redirected_to edit_user_path(user)
      end

      should "not send an email change confirmation email if UserPolicy#resend_email_change? returns false" do
        user = create(:user_with_pending_email_change)

        stub_policy(@superadmin, user, resend_email_change?: false)

        assert_no_enqueued_emails do
          put :resend_email_change, params: { user_id: user }
        end
        assert_not_authorised
      end
    end

    context "signed in as Normal user" do
      setup do
        sign_in(create(:user))
      end

      should "not be authorized" do
        user = create(:user_with_pending_email_change)

        put :resend_email_change, params: { user_id: user }

        assert_not_authorised
      end
    end

    context "not signed in" do
      should "not be allowed access" do
        user = create(:user_with_pending_email_change)

        put :resend_email_change, params: { user_id: user }

        assert_not_authenticated
      end
    end
  end

  context "DELETE cancel_email_change" do
    context "signed in as Superadmin user" do
      setup do
        @superadmin = create(:superadmin_user)
        sign_in(@superadmin)
      end

      should "clear unconfirmed_email & confirmation_token" do
        user = create(:user_with_pending_email_change)

        delete :cancel_email_change, params: { user_id: user }

        user.reload
        assert user.unconfirmed_email.blank?
        assert user.confirmation_token.blank?
      end

      should "redirect to the edit user page" do
        user = create(:user_with_pending_email_change)

        delete :cancel_email_change, params: { user_id: user }

        assert_redirected_to edit_user_path(user)
      end

      should "clear email & token if UserPolicy#cancel_email_change? returns true" do
        user = create(:user_with_pending_email_change)

        stub_policy(@superadmin, user, cancel_email_change?: true)

        delete :cancel_email_change, params: { user_id: user }

        assert user.reload.unconfirmed_email.blank?
      end

      should "not clear email & token if UserPolicy#cancel_email_change? returns false" do
        user = create(:user_with_pending_email_change)

        stub_policy(@superadmin, user, cancel_email_change?: false)

        delete :cancel_email_change, params: { user_id: user }

        assert user.reload.unconfirmed_email.present?
        assert_not_authorised
      end
    end

    context "signed in as Normal user" do
      setup do
        sign_in(create(:user))
      end

      should "not be authorized" do
        user = create(:user_with_pending_email_change)

        delete :cancel_email_change, params: { user_id: user }

        assert_not_authorised
      end
    end

    context "not signed in" do
      should "not be allowed access" do
        user = create(:user_with_pending_email_change)

        delete :cancel_email_change, params: { user_id: user }

        assert_not_authenticated
      end
    end
  end
end
