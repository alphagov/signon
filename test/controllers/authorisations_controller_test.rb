require "test_helper"

class AuthorisationsControllerTest < ActionController::TestCase
  setup do
    @api_user = create(:api_user)
  end

  context "GET new" do
    context "signed in as Superadmin user" do
      setup do
        @superadmin = create(:superadmin_user)
        sign_in @superadmin

        @application = create(:application)
      end

      should "should show a form to authorise api access to a particular application" do
        get :new, params: { api_user_id: @api_user.id }
        assert_select "option[value='#{@application.id}']", @application.name
      end
    end

    context "signed in as Admin user" do
      setup do
        @admin = create(:admin_user)
        sign_in @admin
      end

      should "not be able to authorise API users" do
        get :new, params: { api_user_id: @api_user.id }

        assert_not_authorised
      end
    end
  end

  context "POST create" do
    context "signed in as Superadmin user" do
      setup do
        @superadmin = create(:superadmin_user)
        sign_in @superadmin

        @application = create(:application)
      end

      should "create a new access token and populate flash with it" do
        assert_difference "Doorkeeper::AccessToken.count", 1 do
          post :create, params: { api_user_id: @api_user.id, authorisation: { application_id: @application.id } }
        end

        token = Doorkeeper::AccessToken.last
        assert_equal({ application_name: token.application.name, token: token.token }, flash[:authorisation])
      end

      should "add a 'signin' permission for the authorised application" do
        post :create, params: { api_user_id: @api_user.id, authorisation: { application_id: @application.id } }

        assert @api_user.has_access_to?(@application)
      end

      should "not duplicate 'signin' permission for the authorised application if it already exists" do
        @api_user.grant_application_signin_permission(@application)

        post :create, params: { api_user_id: @api_user.id, authorisation: { application_id: @application.id } }

        assert_equal [SupportedPermission::SIGNIN_NAME], @api_user.permissions_for(@application)
      end
    end
  end

  context "POST revoke" do
    context "signed in as Admin user" do
      setup do
        @admin = create(:admin_user)
        sign_in @admin
      end

      should "not be able to revoke API user's authorisations" do
        access_token = create(:access_token, resource_owner_id: @api_user.id)

        post :revoke, params: { api_user_id: @api_user.id, id: access_token.id }

        assert_not_authorised
      end
    end
  end
end
