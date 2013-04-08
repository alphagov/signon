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
      post :create, user_names_and_emails: users_csv, user: { permissions_attributes: permissions_attributes }

      bi = BatchInvitation.last
      assert_not_nil bi
      assert_equal(permissions_attributes, bi.applications_and_permissions)
      expected_names_and_emails = [["Arthur Dent","a@hhg.com"], ["Tricia McMillan","t@hhg.com"]]
      assert_equal expected_names_and_emails, bi.batch_invitation_users.map { |u| [u.name, u.email] }
    end

    should "queue a job to do the processing" do
      Delayed::Job.expects(:enqueue).with(kind_of(BatchInvitation::Job))
      post :create, user_names_and_emails: users_csv, user: {}
    end

    should "redirect to the batch invitation page and show a flash message" do
      post :create, user_names_and_emails: users_csv, user: { permissions_attributes: {} }

      assert_match(/Scheduled invitation of 2 users/i, flash[:notice])
      assert_redirected_to "/admin/batch_invitations/#{BatchInvitation.last.id}"
    end

    context "no file uploaded" do
      should "redisplay the form and show a flash message" do
        post :create, user_names_and_emails: nil, user: { permissions_attributes: {} }

        assert_template :new
        assert_match(/You must upload a file/i, flash[:alert])
      end
    end

    context "the CSV has all the fields, but not in the expected order" do
      should "process the fields by name" do
        post :create, user_names_and_emails: users_csv("reversed_users.csv"), user: { permissions_attributes: {} }

        bi = BatchInvitation.last
        assert_not_nil bi.batch_invitation_users.find_by_email("a@hhg.com")
        assert_not_nil bi.batch_invitation_users.find_by_email("t@hhg.com")
      end
    end

    context "the CSV has no data rows" do
      should "redisplay the form and show a flash message" do
        post :create, user_names_and_emails: users_csv("empty_users.csv"), user: { permissions_attributes: {} }

        assert_template :new
        assert_match(/no rows/i, flash[:alert])
      end
    end

    context "the CSV format is invalid" do
      should "redisplay the form and show a flash message" do
        post :create, user_names_and_emails: users_csv("invalid_users.csv"), user: { permissions_attributes: {} }

        assert_template :new
        assert_match(/Couldn't understand that file/i, flash[:alert])
      end
    end

    context "the CSV has no headers?" do
      should "redisplay the form and show a flash message" do
        post :create, user_names_and_emails: users_csv("no_headers_users.csv"), user: { permissions_attributes: {} }

        assert_template :new
        assert_match(/must have headers/i, flash[:alert])
      end
    end
  end
end
