require "test_helper"

class BatchInvitationsControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper

  def users_csv(filename = "users.csv")
    Rack::Test::UploadedFile.new("#{Rails.root}/test/controllers/fixtures/#{filename}")
  end

  setup do
    @user = create(:admin_user)
    sign_in @user
  end

  context "GET new" do
    should "render a form" do
      get :new
      assert_response 200
      assert_select "input[type=file]"
    end

    context "some batches created recently" do
      setup do
        @bi = create(:batch_invitation)
        create(:batch_invitation_user, batch_invitation: @bi)
      end

      should "show a table summarising them" do
        get :new
        assert_select "table.recent-batches tbody tr", count: 1
        assert_select "table.recent-batches tbody td", "1 users by #{@bi.user.name} at #{@bi.created_at.to_s(:govuk_date)}"
        assert_select "table.recent-batches tbody td", "In progress. 0 of 1 users processed."
      end
    end

    should "allow selection of an organisation to invite users to" do
      organisation = create(:organisation)
      get :new

      assert_select "#batch_invitation_organisation_id option", organisation.name
    end
  end

  context "POST create" do
    should "create a BatchInvitation and BatchInvitationUsers" do
      app = create(:application)
      post :create, params: { batch_invitation: { user_names_and_emails: users_csv }, user: { supported_permission_ids: [app.signin_permission.id] } }

      bi = BatchInvitation.last
      assert_not_nil bi
      assert_equal [app.signin_permission], bi.supported_permissions
      expected_names_and_emails = [["Arthur Dent", "a@hhg.com"], ["Tricia McMillan", "t@hhg.com"]]
      assert_equal(
        expected_names_and_emails,
        bi.batch_invitation_users.map { |u| [u.name, u.email] },
      )
    end

    should "store the organisation to invite users to" do
      post :create,
           params: { user: { supported_permission_ids: [] },
                     batch_invitation: { user_names_and_emails: users_csv, organisation_id: 3 } }

      bi = BatchInvitation.last

      assert_not_nil bi
      assert_equal 3, bi.organisation_id
    end

    should "store organisation info from the uploaded CSV when logged in as an admin" do
      @user.update!(role: "admin")
      post :create,
           params: { user: { supported_permission_ids: [] },
                     batch_invitation: { user_names_and_emails: users_csv("users_with_orgs.csv"), organisation_id: 3 } }

      bi = BatchInvitation.last

      assert_not_nil bi
      assert_equal 3, bi.organisation_id
      assert_equal "department-of-hats", bi.batch_invitation_users[0].organisation_slug
      assert_nil bi.batch_invitation_users[1].organisation_slug
      assert_equal "cabinet-office", bi.batch_invitation_users[2].organisation_slug
    end

    should "store organisation info from the uploaded CSV when logged in as a superadmin" do
      @user.update!(role: "superadmin")
      post :create,
           params: { user: { supported_permission_ids: [] },
                     batch_invitation: { user_names_and_emails: users_csv("users_with_orgs.csv"), organisation_id: 3 } }

      bi = BatchInvitation.last

      assert_not_nil bi
      assert_equal 3, bi.organisation_id
      assert_equal "department-of-hats", bi.batch_invitation_users[0].organisation_slug
      assert_nil bi.batch_invitation_users[1].organisation_slug
      assert_equal "cabinet-office", bi.batch_invitation_users[2].organisation_slug
    end

    should "queue a job to do the processing" do
      assert_enqueued_jobs 2 do
        post :create, params: { batch_invitation: { user_names_and_emails: users_csv }, user: { supported_permission_ids: [] } }
      end
    end

    should "send an email to signon-alerts" do
      perform_enqueued_jobs do
        post :create, params: { batch_invitation: { user_names_and_emails: users_csv }, user: { supported_permission_ids: [] } }

        email = ActionMailer::Base.deliveries.detect do |m|
          m.to.any? { |to| to =~ /signon-alerts@.*\.gov\.uk/ }
        end
        assert_not_nil email
        assert_equal "[SIGNON] #{@user.name} created a batch of 2 users in development", email.subject
      end
    end

    should "redirect to the batch invitation page and show a flash message" do
      post :create, params: { batch_invitation: { user_names_and_emails: users_csv }, user: { supported_permission_ids: [] } }

      assert_match(/Scheduled invitation of 2 users/i, flash[:notice])
      assert_redirected_to "/batch_invitations/#{BatchInvitation.last.id}"
    end

    context "no file uploaded" do
      should "redisplay the form and show a flash message" do
        post :create, params: { batch_invitation: { user_names_and_emails: nil }, user: { supported_permission_ids: [] } }

        assert_template :new
        assert_match(/You must upload a file/i, flash[:alert])
      end
    end

    context "the CSV has all the fields, but not in the expected order" do
      should "process the fields by name" do
        post :create, params: { batch_invitation: { user_names_and_emails: users_csv("reversed_users.csv") }, user: { supported_permission_ids: [] } }

        bi = BatchInvitation.last
        assert_not_nil bi.batch_invitation_users.find_by(email: "a@hhg.com")
        assert_not_nil bi.batch_invitation_users.find_by(email: "t@hhg.com")
      end
    end

    context "the CSV has no data rows" do
      should "redisplay the form and show a flash message" do
        post :create, params: { batch_invitation: { user_names_and_emails: users_csv("empty_users.csv") }, user: { supported_permission_ids: [] } }

        assert_template :new
        assert_match(/no rows/i, flash[:alert])
      end
    end

    context "the CSV format is invalid" do
      should "redisplay the form and show a flash message" do
        post :create, params: { batch_invitation: { user_names_and_emails: users_csv("invalid_users.csv") }, user: { supported_permission_ids: [] } }

        assert_template :new
        assert_match(/Couldn't understand that file/i, flash[:alert])
      end
    end

    context "the CSV has no headers?" do
      should "redisplay the form and show a flash message" do
        post :create, params: { batch_invitation: { user_names_and_emails: users_csv("no_headers_users.csv") }, user: { supported_permission_ids: [] } }

        assert_template :new
        assert_match(/must have headers/i, flash[:alert])
      end
    end
  end

  context "GET show" do
    setup do
      @bi = create(:batch_invitation)
      @user1 = create(:batch_invitation_user, name: "A", email: "a@m.com", batch_invitation: @bi)
      @user2 = create(:batch_invitation_user, name: "B", email: "b@m.com", batch_invitation: @bi)
    end

    should "list the users being created" do
      get :show, params: { id: @bi.id }
      assert_select "table.batch-invitation-users tbody tr", 2
      assert_select "table.batch-invitation-users td", "a@m.com"
      assert_select "table.batch-invitation-users td", "b@m.com"
    end

    should "include a meta refresh" do
      get :show, params: { id: @bi.id }
      assert_select 'head meta[http-equiv=refresh][content="3"]'
    end

    should "show the state of the processing" do
      @user1.update_column(:outcome, "failed")
      get :show, params: { id: @bi.id }
      assert_select "div.alert", /In progress/i
      assert_select "div.alert", /1 of 2 users processed/i
    end

    should "show the outcome for each user" do
      @user1.update_column(:outcome, "failed")
      get :show, params: { id: @bi.id }
      assert_select "td", /Failed/i
    end

    context "processing complete" do
      setup do
        @bi.update_column(:outcome, "success")
        get :show, params: { id: @bi.id }
      end

      should "show the state of the processing" do
        assert_select "div.alert", "2 users processed."
      end

      should "no longer include the meta refresh" do
        assert_select "head meta[http-equiv=refresh]", count: 0
      end
    end
  end
end
