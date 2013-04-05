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
    should "create the users and assign them permissions" do
      app = FactoryGirl.create(:application)

      permissions_attributes = {
        permissions_attributes: {
          0 => {
            application_id: "#{app.id}",
            id: "",
            signin_permission: "1",
            permissions: []
          }
        }
      }
      post :create, user_names_and_emails: users_csv, user: permissions_attributes

      arthur = User.find_by_email("a@hhg.com")
      tricia = User.find_by_email("t@hhg.com")
      assert_not_nil arthur
      assert_not_nil tricia

      assert_equal "Arthur Dent", arthur.name
      assert_equal "Tricia McMillan", tricia.name

      arthurs_permissions_for_app = arthur.permissions.where(application_id: app.id).first
      assert_not_nil arthurs_permissions_for_app
      assert_equal ["signin"], arthurs_permissions_for_app.permissions

      tricias_permissions_for_app = tricia.permissions.where(application_id: app.id).first
      assert_not_nil tricias_permissions_for_app
      assert_equal ["signin"], tricias_permissions_for_app.permissions
    end

    should "trigger an invitation email" do
      post :create, user_names_and_emails: users_csv, user: { permissions_attributes: {} }

      email = ActionMailer::Base.deliveries.last
      assert_not_nil email
      assert_equal "Please confirm your account", email.subject
      assert_equal ["t@hhg.com"], email.to
    end

    should "redirect to the index and show a flash message" do
      post :create, user_names_and_emails: users_csv, user: { permissions_attributes: {} }

      assert_match(/Created 2 users/i, flash[:notice])
      assert_redirected_to admin_users_path
    end

    context "one of the users already exists" do
      setup do
        ActionMailer::Base.deliveries = []
        @user = FactoryGirl.create(:user, name: "Arthur Dent", email: "a@hhg.com")
        post :create, user_names_and_emails: users_csv("users.csv"), user: { permissions_attributes: {} }
      end

      should "create the other users" do
        assert_not_nil User.find_by_email("t@hhg.com")
      end

      should "only send the invitation to the new user" do
        assert_equal 1, ActionMailer::Base.deliveries.size
      end

      should "skip that user entirely, including not altering permissions" do
        app = FactoryGirl.create(:application)
        another_app = FactoryGirl.create(:application)
        FactoryGirl.create(:supported_permission, application_id: another_app.id, name: "foo")
        @user.grant_permissions(another_app, ["signin", "foo"])

        permissions_attributes = {
          permissions_attributes: {
            0 => {
              application_id: "#{app.id}",
              id: "",
              signin_permission: "1",
              permissions: []
            },
            1 => {
              application_id: "#{another_app.id}",
              id: "",
              signin_permission: "1",
              permissions: ["signin"]
            }
          }
        }
        post :create, user_names_and_emails: users_csv, user: permissions_attributes
        @user.reload

        app_permissions = @user.permissions.where(application_id: app.id).first
        assert_nil app_permissions

        another_app_permissions = @user.permissions.where(application_id: another_app.id).first
        assert_equal ["signin", "foo"], another_app_permissions.permissions
      end
    end

    context "one of the rows is missing a name or email" do
      setup do
        post :create, user_names_and_emails: users_csv("partial_users.csv"), user: { permissions_attributes: {} }
      end

      should "create the other users" do
        assert_nil User.find_by_email("a@hhg.com")
        assert_not_nil User.find_by_email("t@hhg.com")
      end

      should "indicate the mixed outcome in the flash message" do
        assert_match(/Created 1 users/i, flash[:notice])
        assert_match(/Failed to create 1 users/i, flash[:alert])
      end
    end

    context "sending one of the emails fails" do
      should "create the other users" #do
        # TODO need another way to test this.
        #
        # Devise::Mailer.any_instance.stubs(:mail).with(anything)
        #     .raises(StandardError)
        #     .then.returns(true)
        # post :create, user_names_and_emails: users_csv, user: { permissions_attributes: {} }
        # assert_equal 1, ActionMailer::Base.deliveries.size
      # end

      should "indicate the mixed outcome in the flash message"
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

        assert_not_nil User.find_by_email("a@hhg.com")
        assert_not_nil User.find_by_email("t@hhg.com")
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
