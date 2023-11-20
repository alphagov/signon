require "test_helper"

class Users::EmailsControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  context "GET edit" do
    context "signed in as Admin user" do
      setup do
        @admin = create(:admin_user)
        sign_in(@admin)
      end

      should "display form with email field" do
        user = create(:user, email: "user@gov.uk")

        get :edit, params: { user_id: user }

        assert_template :edit
        assert_select "form[action='#{user_email_path(user)}']" do
          assert_select "input[name='user[email]']", value: "user@gov.uk"
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

        user_policy = stub_everything("user-policy", edit?: true)
        UserPolicy.stubs(:new).returns(user_policy)

        get :edit, params: { user_id: user }

        assert_template :edit
      end

      should "not authorize access if UserPolicy#edit? returns false" do
        user = create(:user)

        user_policy = stub_everything("user-policy", edit?: false)
        UserPolicy.stubs(:new).returns(user_policy)

        get :edit, params: { user_id: user }

        assert_not_authorised
      end

      should "redirect to account edit email page if admin is acting on their own user" do
        get :edit, params: { user_id: @admin }

        assert_redirected_to edit_account_email_path
      end
    end

    context "signed in as Normal user" do
      setup do
        sign_in(create(:user))
      end

      should "not find the user" do
        user = create(:user)

        assert_raises ActiveRecord::RecordNotFound do
          get :edit, params: { user_id: user }
        end
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

          expected_subject = "Your GOV.UK Signon development email address has been updated"
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

      should "record email change" do
        user = create(:user, email: "user@gov.uk")

        EventLog.expects(:record_email_change).with(user, "user@gov.uk", "new-user@gov.uk", @admin)

        put :update, params: { user_id: user, user: { email: "new-user@gov.uk" } }
      end

      should "should not record email change if email has not changed" do
        user = create(:user, email: "user@gov.uk")

        EventLog.expects(:record_email_change).never

        put :update, params: { user_id: user, user: { email: "user@gov.uk" } }
      end

      should "push changes out to apps" do
        user = create(:user)
        PermissionUpdater.expects(:perform_on).with(user).once

        put :update, params: { user_id: user, user: { email: "new-user@gov.uk" } }
      end

      should "redirect to edit user page and display success notice" do
        user = create(:user, email: "user@gov.uk")

        put :update, params: { user_id: user, user: { email: "new-user@gov.uk" } }

        assert_redirected_to edit_user_path(user)
        assert "Updated user new-user@gov.uk successfully", flash[:notice]
      end

      should "update user email if UserPolicy#update? returns true" do
        user = create(:user, email: "user@gov.uk")

        user_policy = stub_everything("user-policy", update?: true)
        UserPolicy.stubs(:new).returns(user_policy)

        put :update, params: { user_id: user, user: { email: "new-user@gov.uk" } }

        assert_equal "new-user@gov.uk", user.reload.email
      end

      should "not update user email if UserPolicy#update? returns false" do
        user = create(:user, email: "user@gov.uk")

        user_policy = stub_everything("user-policy", update?: false)
        UserPolicy.stubs(:new).returns(user_policy)

        put :update, params: { user_id: user, user: { email: "new-user@gov.uk" } }

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

      should "not find the user" do
        user = create(:user)

        assert_raises ActiveRecord::RecordNotFound do
          put :update, params: { user_id: user, user: { email: "new-user@gov.uk" } }
        end
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

  context "PUT resend_email_change" do
    context "signed in as Admin user" do
      setup do
        sign_in(create(:admin_user))
      end

      should "send an email change confirmation email" do
        perform_enqueued_jobs do
          user = create(:user_with_pending_email_change)

          put :resend_email_change, params: { user_id: user }

          assert_equal "Confirm your email change", ActionMailer::Base.deliveries.last.subject
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

        user_policy = stub_everything("user-policy", resend_email_change?: true)
        UserPolicy.stubs(:new).returns(user_policy)

        assert_enqueued_emails 1 do
          put :resend_email_change, params: { user_id: user }
        end
        assert_redirected_to edit_user_path(user)
      end

      should "not send an email change confirmation email if UserPolicy#resend_email_change? returns false" do
        user = create(:user_with_pending_email_change)

        user_policy = stub_everything("user-policy", resend_email_change?: false)
        UserPolicy.stubs(:new).returns(user_policy)

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

      should "not find the user" do
        user = create(:user_with_pending_email_change)

        assert_raises ActiveRecord::RecordNotFound do
          put :resend_email_change, params: { user_id: user }
        end
      end
    end

    context "not signed in" do
      should "not be allowed access" do
        user = create(:user_with_pending_email_change)

        get :resend_email_change, params: { user_id: user }

        assert_not_authenticated
      end
    end
  end

  context "DELETE cancel_email_change" do
    context "signed in as Admin user" do
      setup do
        sign_in(create(:admin_user))
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

        user_policy = stub_everything("user-policy", cancel_email_change?: true)
        UserPolicy.stubs(:new).returns(user_policy)

        put :cancel_email_change, params: { user_id: user }

        assert user.reload.unconfirmed_email.blank?
      end

      should "not clear email & token if UserPolicy#cancel_email_change? returns false" do
        user = create(:user_with_pending_email_change)

        user_policy = stub_everything("user-policy", cancel_email_change?: false)
        UserPolicy.stubs(:new).returns(user_policy)

        put :cancel_email_change, params: { user_id: user }

        assert user.reload.unconfirmed_email.present?
        assert_not_authorised
      end
    end

    context "signed in as Normal user" do
      setup do
        sign_in(create(:user))
      end

      should "not find the user" do
        user = create(:user_with_pending_email_change)

        assert_raises ActiveRecord::RecordNotFound do
          put :cancel_email_change, params: { user_id: user }
        end
      end
    end

    context "not signed in" do
      should "not be allowed access" do
        user = create(:user_with_pending_email_change)

        get :cancel_email_change, params: { user_id: user }

        assert_not_authenticated
      end
    end
  end
end
