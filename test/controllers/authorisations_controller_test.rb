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

      should "display breadcrumb links" do
        get :new, params: { api_user_id: @api_user.id }

        assert_select ".govuk-breadcrumbs" do
          assert_select "a[href='#{root_path}']"
          assert_select "a[href='#{api_users_path}']"
          assert_select "a[href='#{edit_api_user_path(@api_user)}']"
          assert_select "a[href='#{manage_tokens_api_user_path(@api_user)}']"
        end
      end

      should "should show a form to authorise API access to a particular application" do
        get :new, params: { api_user_id: @api_user }
        assert_select "option[value='#{@application.id}']", @application.name
      end

      should "should show cancel link to return to manage tokens page" do
        get :new, params: { api_user_id: @api_user.id }

        assert_select "a[href='#{manage_tokens_api_user_path(@api_user)}']", text: "Cancel"
      end

      should "authorize access if AuthorisationPolicy#new? returns true" do
        policy = stub_everything("policy", new?: true).responds_like_instance_of(AuthorisationPolicy)
        AuthorisationPolicy.stubs(:new).returns(policy)
        stub_policy_for_navigation_links(@superadmin)

        get :new, params: { api_user_id: @api_user.id }

        assert_template :new
      end

      should "not authorize access if AuthorisationPolicy#new? returns false" do
        policy = stub_everything("policy", new?: false).responds_like_instance_of(AuthorisationPolicy)
        AuthorisationPolicy.stubs(:new).returns(policy)
        stub_policy_for_navigation_links(@superadmin)

        get :new, params: { api_user_id: @api_user.id }

        assert_not_authorised
      end
    end

    context "signed in as Admin user" do
      setup do
        @admin = create(:admin_user)
        sign_in @admin
      end

      should "not be able to authorise API users" do
        get :new, params: { api_user_id: @api_user }

        assert_not_authorised
      end
    end

    context "not signed in" do
      should "not be allowed access" do
        get :new, params: { api_user_id: @api_user.id }

        assert_not_authenticated
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
          post :create, params: { api_user_id: @api_user, authorisation: { application_id: @application } }
        end

        token = Doorkeeper::AccessToken.last
        assert_equal({ application_name: token.application.name, token: token.token }, flash[:authorisation])
      end

      should "add a 'signin' permission for the authorised application" do
        post :create, params: { api_user_id: @api_user, authorisation: { application_id: @application } }

        assert @api_user.has_access_to?(@application)
      end

      should "not duplicate 'signin' permission for the authorised application if it already exists" do
        @api_user.grant_application_signin_permission(@application)

        post :create, params: { api_user_id: @api_user, authorisation: { application_id: @application } }

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

        post :revoke, params: { api_user_id: @api_user, id: access_token }

        assert_not_authorised
      end
    end
  end
end
