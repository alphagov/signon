require "test_helper"

class BatchInvitationsControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper

  def users_csv(filename = "users.csv")
    Rack::Test::UploadedFile.new(Rails.root.join("test/controllers/fixtures/#{filename}"))
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

    should "allow selection of an organisation to invite users to" do
      organisation = create(:organisation)
      get :new

      assert_select "#batch_invitation_organisation_id option", organisation.name
    end
  end

  context "POST create" do
    should "create a BatchInvitation and BatchInvitationUsers" do
      create(:application)
      post :create, params: { batch_invitation: { user_names_and_emails: users_csv } }

      bi = BatchInvitation.last
      assert_not_nil bi
      expected_names_and_emails = [["Arthur Dent", "a@hhg.com"], ["Tricia McMillan", "t@hhg.com"]]
      assert_equal(
        expected_names_and_emails,
        bi.batch_invitation_users.map { |u| [u.name, u.email] },
      )
    end

    should "store the organisation to invite users to" do
      post :create, params: { batch_invitation: { user_names_and_emails: users_csv, organisation_id: 3 } }

      bi = BatchInvitation.last

      assert_not_nil bi
      assert_equal 3, bi.organisation_id
    end

    should "store organisation info from the uploaded CSV when logged in as an admin" do
      @user.update!(role: Roles::Admin.role_name)
      post :create,
           params: { batch_invitation: { user_names_and_emails: users_csv("users_with_orgs.csv"), organisation_id: 3 } }

      bi = BatchInvitation.last

      assert_not_nil bi
      assert_equal 3, bi.organisation_id
      assert_equal "department-of-hats", bi.batch_invitation_users[0].organisation_slug
      assert_nil bi.batch_invitation_users[1].organisation_slug
      assert_equal "cabinet-office", bi.batch_invitation_users[2].organisation_slug
    end

    should "store organisation info from the uploaded CSV when logged in as a superadmin" do
      @user.update!(role: Roles::Superadmin.role_name)
      post :create,
           params: { batch_invitation: { user_names_and_emails: users_csv("users_with_orgs.csv"), organisation_id: 3 } }

      bi = BatchInvitation.last

      assert_not_nil bi
      assert_equal 3, bi.organisation_id
      assert_equal "department-of-hats", bi.batch_invitation_users[0].organisation_slug
      assert_nil bi.batch_invitation_users[1].organisation_slug
      assert_equal "cabinet-office", bi.batch_invitation_users[2].organisation_slug
    end

    should "redirect to the batch invitation permissions page and show a flash message" do
      post :create, params: { batch_invitation: { user_names_and_emails: users_csv } }

      assert_redirected_to "/batch_invitations/#{BatchInvitation.last.id}/permissions/new"
    end

    context "no file uploaded" do
      should "redisplay the form and show a flash message" do
        post :create, params: { batch_invitation: { user_names_and_emails: nil } }

        assert_template :new
        assert_match(/You must upload a file/i, flash[:alert])
      end
    end

    context "the CSV contains one or more email addresses that aren't valid" do
      should "redisplay the form and show a flash message" do
        post :create, params: { batch_invitation: { user_names_and_emails: users_csv("users_with_non_valid_emails.csv") } }

        assert_template :new
        assert_match(/One or more emails were invalid/i, flash[:alert])
      end
    end

    context "the CSV has all the fields, but not in the expected order" do
      should "process the fields by name" do
        post :create, params: { batch_invitation: { user_names_and_emails: users_csv("reversed_users.csv") } }

        bi = BatchInvitation.last
        assert_not_nil bi.batch_invitation_users.find_by(email: "a@hhg.com")
        assert_not_nil bi.batch_invitation_users.find_by(email: "t@hhg.com")
      end
    end

    context "the CSV has no data rows" do
      should "redisplay the form and show a flash message" do
        post :create, params: { batch_invitation: { user_names_and_emails: users_csv("empty_users.csv") } }

        assert_template :new
        assert_match(/no rows/i, flash[:alert])
      end
    end

    context "the CSV format is invalid" do
      should "redisplay the form and show a flash message" do
        post :create, params: { batch_invitation: { user_names_and_emails: users_csv("invalid_users.csv") } }

        assert_template :new
        assert_match(/Couldn't understand that file/i, flash[:alert])
      end
    end

    context "the CSV has no headers?" do
      should "redisplay the form and show a flash message" do
        post :create, params: { batch_invitation: { user_names_and_emails: users_csv("no_headers_users.csv") } }

        assert_template :new
        assert_match(/must have headers/i, flash[:alert])
      end
    end
  end

  context "GET show" do
    context "processing in progress" do
      setup do
        @bi = create(:batch_invitation, :in_progress)
        @user1 = create(:batch_invitation_user, name: "A", email: "a@m.com", batch_invitation: @bi)
        @user2 = create(:batch_invitation_user, name: "B", email: "b@m.com", batch_invitation: @bi)
      end

      should "list the users being created" do
        get :show, params: { id: @bi.id }
        assert_select "table tbody tr", 2
        assert_select "table td", "a@m.com"
        assert_select "table td", "b@m.com"
      end

      should "include a meta refresh" do
        get :show, params: { id: @bi.id }
        assert_select 'head meta[http-equiv=refresh][content="3"]'
      end

      should "show the state of the processing" do
        @user1.update_column(:outcome, "failed")
        get :show, params: { id: @bi.id }
        assert_select "section.gem-c-notice", /In progress/i
        assert_select "section.gem-c-notice", /1 of 2 users processed/i
      end

      should "show the outcome for each user" do
        @user1.update_column(:outcome, "failed")
        get :show, params: { id: @bi.id }
        assert_select "td", /Failed/i
      end
    end

    context "processing complete" do
      setup do
        @bi = create(:batch_invitation, outcome: "success")
        create(:batch_invitation_user, name: "A", email: "a@m.com", batch_invitation: @bi)
        create(:batch_invitation_user, name: "B", email: "b@m.com", batch_invitation: @bi)
        get :show, params: { id: @bi.id }
      end

      should "show the state of the processing" do
        assert_select "div.gem-c-success-alert", /2 users processed/
      end

      should "no longer include the meta refresh" do
        assert_select "head meta[http-equiv=refresh]", count: 0
      end
    end

    context "batch invitation doesn't have any permissions yet" do
      setup do
        @bi = create(:batch_invitation)
        create(:batch_invitation_user, name: "A", email: "a@m.com", batch_invitation: @bi)
        create(:batch_invitation_user, name: "B", email: "b@m.com", batch_invitation: @bi)
        get :show, params: { id: @bi.id }
      end

      should "explain the problem with the batch invitation" do
        assert_select "div.gem-c-error-alert",
                      /Batch invitation doesn't have any permissions yet./
      end

      should "not include the meta refresh" do
        assert_select "head meta[http-equiv=refresh]", count: 0
      end
    end
  end
end
