require "test_helper"

class Users::EmailsControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  context "GET edit" do
    context "signed in as Admin user" do
      setup do
        sign_in(create(:admin_user))
      end

      should "display form with email field" do
        user = create(:user, email: "user@gov.uk")

        get :edit, params: { user_id: user }

        assert_template :edit
        assert_select "form[action='#{user_email_path(user)}']" do
          assert_select "input[name='user[email]']", value: "user@gov.uk"
        end
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

        assert_redirected_to new_user_session_path
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
          assert_select "li", text: "Email can't be blank"
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

        get :edit, params: { user_id: user }

        assert_redirected_to new_user_session_path
      end
    end
  end
end
