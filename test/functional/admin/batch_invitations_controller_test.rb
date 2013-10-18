require 'test_helper'

class Admin::BatchInvitationsControllerTest < ActionController::TestCase

  def users_csv(filename = "users.csv")
    Rack::Test::UploadedFile.new("#{Rails.root}/test/functional/admin/fixtures/#{filename}")
  end

  setup do
    @user = FactoryGirl.create(:user, role: "admin")
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
        @bi = FactoryGirl.create(:batch_invitation)
        FactoryGirl.create(:batch_invitation_user, batch_invitation: @bi)
      end

      should "show a table summarising them" do
        get :new
        assert_select "table.recent-batches tbody tr", count: 1
        assert_select "table.recent-batches tbody td", "1 users by #{@bi.user.name} at #{@bi.created_at.strftime("%H:%M on %e %B %Y")}"
        assert_select "table.recent-batches tbody td", "In progress. 0 of 1 users processed."
      end
    end
  end

  context "POST create" do
    should "create a BatchInvitation and BatchInvitationUsers" do
      app = FactoryGirl.create(:application)
      permissions_attributes = {
        0 => {
          "application_id" => "#{app.id}",
          "id" => "",
          "signin_permission" => "1",
          "permissions" => []
        }
      }
      post :create, batch_invitation: { user_names_and_emails: users_csv }, user: { permissions_attributes: permissions_attributes }

      translated_permissions_attributes = {
        0 => {
          "application_id" => "#{app.id}",
          "id" => "",
          "permissions" => ["signin"]
        }
      }
      bi = BatchInvitation.last
      assert_not_nil bi
      assert_equal(translated_permissions_attributes, bi.applications_and_permissions)
      expected_names_and_emails = [["Arthur Dent","a@hhg.com"], ["Tricia McMillan","t@hhg.com"]]
      assert_equal expected_names_and_emails, bi.batch_invitation_users.map { |u| [u.name, u.email] }
    end

    should "queue a job to do the processing" do
      Delayed::Job.expects(:enqueue).with(kind_of(BatchInvitation::Job))
      post :create, batch_invitation: { user_names_and_emails: users_csv }, user: { permissions_attributes: {} }
    end

    should "send an email to signon-alerts" do
      post :create, batch_invitation: { user_names_and_emails: users_csv }, user: { permissions_attributes: {} }

      email = ActionMailer::Base.deliveries.last
      assert_not_nil email
      assert_equal ["signon-alerts@theodi.org"], email.to
    end

    should "redirect to the batch invitation page and show a flash message" do
      post :create, batch_invitation: { user_names_and_emails: users_csv }, user: { permissions_attributes: {} }

      assert_match(/Scheduled invitation of 2 users/i, flash[:notice])
      assert_redirected_to "/admin/batch_invitations/#{BatchInvitation.last.id}"
    end

    context "no file uploaded" do
      should "redisplay the form and show a flash message" do
        post :create, batch_invitation: { user_names_and_emails: nil }, user: { permissions_attributes: {} }

        assert_template :new
        assert_match(/You must upload a file/i, flash[:alert])
      end
    end

    context "the CSV has all the fields, but not in the expected order" do
      should "process the fields by name" do
        post :create, batch_invitation: { user_names_and_emails: users_csv("reversed_users.csv") }, user: { permissions_attributes: {} }

        bi = BatchInvitation.last
        assert_not_nil bi.batch_invitation_users.find_by_email("a@hhg.com")
        assert_not_nil bi.batch_invitation_users.find_by_email("t@hhg.com")
      end
    end

    context "the CSV has no data rows" do
      should "redisplay the form and show a flash message" do
        post :create, batch_invitation: { user_names_and_emails: users_csv("empty_users.csv") }, user: { permissions_attributes: {} }

        assert_template :new
        assert_match(/no rows/i, flash[:alert])
      end
    end

    context "the CSV format is invalid" do
      should "redisplay the form and show a flash message" do
        post :create, batch_invitation: { user_names_and_emails: users_csv("invalid_users.csv") }, user: { permissions_attributes: {} }

        assert_template :new
        assert_match(/Couldn't understand that file/i, flash[:alert])
      end
    end

    context "the CSV has no headers?" do
      should "redisplay the form and show a flash message" do
        post :create, batch_invitation: { user_names_and_emails: users_csv("no_headers_users.csv") }, user: { permissions_attributes: {} }

        assert_template :new
        assert_match(/must have headers/i, flash[:alert])
      end
    end
  end

  context "GET show" do
    setup do
      @bi = FactoryGirl.create(:batch_invitation)
      @user1 = FactoryGirl.create(:batch_invitation_user, name: "A", email: "a@m.com", batch_invitation: @bi)
      @user2 = FactoryGirl.create(:batch_invitation_user, name: "B", email: "b@m.com", batch_invitation: @bi)
    end

    should "list the users being created" do
      get :show, id: @bi.id
      assert_select "table.batch-invitation-users tbody tr", 2
      assert_select "table.batch-invitation-users td", "a@m.com"
      assert_select "table.batch-invitation-users td", "b@m.com"
    end

    should "include a meta refresh" do
      get :show, id: @bi.id
      assert_select "head meta[http-equiv=refresh][content=3]"
    end

    should "show the state of the processing" do
      @user1.update_column(:outcome, "failed")
      get :show, id: @bi.id
      assert_select "div.alert", /In progress/i
      assert_select "div.alert", /1 of 2 users processed/i
    end

    should "show the outcome for each user" do
      @user1.update_column(:outcome, "failed")
      get :show, id: @bi.id
      assert_select "td", /Failed/i
    end

    context "processing complete" do
      setup do
        @bi.update_column(:outcome, "success")
        get :show, id: @bi.id
      end

      should "show the state of the processing" do
        assert_select "div.alert", /Success/i
      end

      should "no longer include the meta refresh" do
        assert_select "head meta[http-equiv=refresh]", count: 0
      end
    end
  end
end
