require "test_helper"

class BatchInvitationPermissionsControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = create(:admin_user)
    sign_in @user

    @app = create(:application, name: "Profound Publisher", with_supported_permissions: %w[reader])

    @batch_invitation = create(:batch_invitation, user: @user)
    create(
      :batch_invitation_user,
      name: "Darayavaush Ayers",
      email: "darayavaush.ayers@department.gov.uk",
      batch_invitation: @batch_invitation,
    )
    create(
      :batch_invitation_user,
      name: "Precious Kumar",
      email: "precious.kumar@department.gov.uk",
      batch_invitation: @batch_invitation,
    )
  end

  context "GET new" do
    should "not allow access if batch invitation already has permissions" do
      @batch_invitation.supported_permission_ids = [@app.signin_permission.id]
      @batch_invitation.save!

      get :new, params: { batch_invitation_id: @batch_invitation.id }

      assert_match(/Permissions have already been set for this batch of users/, flash[:alert])
      assert_redirected_to "/batch_invitations/#{@batch_invitation.id}"
    end

    should "allow selection of application permissions to grant to users" do
      get :new, params: { batch_invitation_id: @batch_invitation.id }

      assert_select "label", "Has access to Profound Publisher?"
      assert_select "label", "reader"
    end

    should "render form checkbox inputs for permissions" do
      application = create(:application)
      signin_permission = application.signin_permission
      other_permission = create(:supported_permission)

      get :new, params: { batch_invitation_id: @batch_invitation.id }

      assert_select "form" do
        assert_select "input[type='checkbox'][name='user[supported_permission_ids][]'][value='#{signin_permission.to_param}']"
        assert_select "input[type='checkbox'][name='user[supported_permission_ids][]'][value='#{other_permission.to_param}']"
      end
    end

    should "render filter for option-select component when app has more than 4 permissions" do
      application = create(:application)
      4.times { create(:supported_permission, application:) }
      assert application.supported_permissions.count > 4

      get :new, params: { batch_invitation_id: @batch_invitation.id }

      assert_select "form" do
        assert_select ".gem-c-option-select[data-filter-element]"
      end
    end
  end

  context "POST create" do
    should "not accept submission if batch invitation already has permissions" do
      @batch_invitation.supported_permission_ids = [@app.signin_permission.id]
      @batch_invitation.save!

      post :create, params: { batch_invitation_id: @batch_invitation.id }

      assert_match(/Permissions have already been set for this batch of users/, flash[:alert])
      assert_redirected_to "/batch_invitations/#{@batch_invitation.id}"
    end

    should "grant selected permissions and default permissions to BatchInvitation" do
      support_app = create(:application, name: "Support")
      support_app.signin_permission.update!(default: true)

      post :create, params: {
        batch_invitation_id: @batch_invitation.id,
        user: { supported_permission_ids: [@app.signin_permission.id] },
      }

      assert_equal [@app.signin_permission, support_app.signin_permission],
                   @batch_invitation.supported_permissions
    end

    context "with no permissions selected" do
      should "still grant default permissions to BatchInvitation" do
        support_app = create(:application, name: "Support")
        support_app.signin_permission.update!(default: true)

        post :create, params: { batch_invitation_id: @batch_invitation.id }

        assert_equal [support_app.signin_permission],
                     @batch_invitation.supported_permissions
      end
    end

    should "send an email to signon-alerts" do
      perform_enqueued_jobs do
        post :create, params: { batch_invitation_id: @batch_invitation.id }

        email = ActionMailer::Base.deliveries.detect do |m|
          m.to.any? { |to| to =~ /signon-alerts@.*\.gov\.uk/ }
        end
        assert_not_nil email
        assert_equal "[SIGNON] #{@user.name} created a batch of 2 users in development", email.subject
      end
    end

    should "redirect to the batch invitation page and show a flash message" do
      post :create, params: { batch_invitation_id: @batch_invitation.id }

      assert_match(/Scheduled invitation of 2 users/i, flash[:notice])
      assert_redirected_to "/batch_invitations/#{@batch_invitation.id}"
    end
  end
end
