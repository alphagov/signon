require "test_helper"

class ApiUsersControllerTest < ActionController::TestCase
  context "as admin user" do
    setup do
      @admin = create(:admin_user)
      sign_in @admin
    end

    should "not be able to access API user's list" do
      get :index

      assert_redirected_to root_path
      assert_equal "You do not have permission to perform this action.", flash[:alert]
    end

    should "not be able to view API user create form" do
      get :new

      assert_redirected_to root_path
      assert_equal "You do not have permission to perform this action.", flash[:alert]
    end
  end

  context "as superadmin" do
    setup do
      @superadmin = create(:superadmin_user)
      sign_in @superadmin
    end

    context "GET index" do
      should "list api users" do
        create(:api_user, email: "api_user@email.com")
        get :index
        assert_select "td.email", /api_user@email.com/
      end

      should "not list web users" do
        create(:user, email: "web_user@email.com")
        get :index
        assert_select "td.email", count: 0, text: /web_user@email.com/
      end
    end

    context "POST create" do
      should "create a new API user" do
        assert_difference "ApiUser.count", 1 do
          post :create, params: { api_user: { name: "Content Store Application", email: "content.store@gov.uk" } }
        end
      end

      should "log API user created event in the api users event log" do
        EventLog.stubs(:record_event) # to ignore logs being created, other than the one under test
        EventLog.expects(:record_event).with(instance_of(ApiUser), EventLog::API_USER_CREATED, initiator: @superadmin, ip_address: request.remote_ip)
        post :create, params: { api_user: { name: "Content Store Application", email: "content.store@gov.uk" } }
      end

      should "redisplay the form with errors if save fails" do
        post :create, params: { api_user: { name: "Content Store Application", email: "content.store at gov uk" } }

        assert_template :new
        assert_select "div.alert ul li", "Email is invalid"
      end
    end

    context "GET edit" do
      should "show the form" do
        api_user = create(:api_user)

        get :edit, params: { id: api_user.id }

        assert_select "input[name='api_user[name]'][value='#{api_user.name}']"
        assert_select "input[name='api_user[email]'][value='#{api_user.email}']"
      end
    end

    context "PUT update" do
      should "update the user" do
        api_user = create(:api_user, name: "Old Name")

        put :update, params: { id: api_user.id, api_user: { name: "New Name" } }

        assert_equal "New Name", api_user.reload.name
        assert_redirected_to :api_users
        assert_equal "Updated API user #{api_user.email} successfully", flash[:notice]
      end

      should "redisplay the form with errors if save fails" do
        api_user = create(:api_user)

        put :update, params: { id: api_user.id, api_user: { name: "" } }

        assert_template :edit
        assert_select "div.alert ul li", "Name can't be blank"
      end

      should "push permission changes out to apps" do
        application = create(:application)
        api_user = create(:api_user)

        PermissionUpdater.expects(:perform_on).with(api_user).once

        put :update,
            params: {
              "id" => api_user.id,
              "api_user" => { "name" => api_user.name,
                              "email" => api_user.email,
                              "permissions_attributes" => { "0" => { "application_id" => application.id, "id" => "", "permissions" => %w[admin] } } },
            }
      end
    end
  end
end
