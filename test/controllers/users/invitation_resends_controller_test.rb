require "test_helper"

class Users::InvitationResendsControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  context "GET edit" do
    context "signed in as Admin user" do
      setup do
        @admin = create(:admin_user)
        sign_in(@admin)
      end

      should "display form with submit button & cancel link" do
        user = create(:invited_user)

        get :edit, params: { user_id: user }

        assert_template :edit
        assert_select "form[action='#{user_invitation_resend_path(user)}']" do
          assert_select "button[type='submit']", text: "Resend signup email"
          assert_select "a[href='#{edit_user_path(user)}']", text: "Cancel"
        end
      end

      should "authorize access if UserPolicy#resend_invitation? returns true" do
        user = create(:invited_user)

        user_policy = stub_everything("user-policy", resend_invitation?: true)
        UserPolicy.stubs(:new).returns(user_policy)

        get :edit, params: { user_id: user }

        assert_template :edit
      end

      should "not authorize access if UserPolicy#resend_invitation? returns false" do
        user = create(:invited_user)

        user_policy = stub_everything("user-policy", resend_invitation?: false)
        UserPolicy.stubs(:new).returns(user_policy)

        get :edit, params: { user_id: user }

        assert_not_authorised
      end

      should "redirect to edit user page if user has already accepted invitation" do
        user = create(:active_user, email: "user@gov.uk")

        get :edit, params: { user_id: user }

        assert_equal "Invitation for user@gov.uk has already been accepted", flash[:notice]
        assert_redirected_to edit_user_path(user)
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

      should "resend signup email" do
        user = create(:invited_user)

        perform_enqueued_jobs do
          put :update, params: { user_id: user }
        end

        email = ActionMailer::Base.deliveries.last
        assert email.present?
        assert_equal "Set up your GOV.UK publishing account", email.subject
      end

      should "update invitation sent timestamp" do
        user = create(:invited_user)

        freeze_time do
          put :update, params: { user_id: user }

          assert_equal Time.current, user.reload.invitation_sent_at
        end
      end

      should "redirect to edit user page and display success notice" do
        user = create(:invited_user, email: "user@gov.uk")

        put :update, params: { user_id: user }

        assert_redirected_to edit_user_path(user)
        assert_equal "Resent account signup email to user@gov.uk", flash[:notice]
      end

      should "resend signup email if UserPolicy#resend_invitation? returns true" do
        user = create(:invited_user)

        user_policy = stub_everything("user-policy", resend_invitation?: true)
        UserPolicy.stubs(:new).returns(user_policy)

        assert_enqueued_emails(1) do
          put :update, params: { user_id: user }
        end
      end

      should "not resend signup email if UserPolicy#resend_invitation? returns false" do
        user = create(:invited_user)

        user_policy = stub_everything("user-policy", resend_invitation?: false)
        UserPolicy.stubs(:new).returns(user_policy)

        put :update, params: { user_id: user }

        assert_no_enqueued_emails do
          put :update, params: { user_id: user }
        end
      end

      should "redirect to edit user page if user has already accepted invitation" do
        user = create(:active_user, email: "user@gov.uk")

        get :update, params: { user_id: user }

        assert_equal "Invitation for user@gov.uk has already been accepted", flash[:notice]
        assert_redirected_to edit_user_path(user)
      end
    end

    context "signed in as Normal user" do
      setup do
        sign_in(create(:user))
      end

      should "not be authorized" do
        user = create(:invited_user)

        put :update, params: { user_id: user }

        assert_not_authorised
      end
    end

    context "not signed in" do
      should "not be allowed access" do
        user = create(:invited_user)

        put :update, params: { user_id: user }

        assert_not_authenticated
      end
    end
  end
end
