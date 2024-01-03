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

      should "create a new access token" do
        post :create, params: { api_user_id: @api_user, authorisation: { application_id: @application } }

        token = @api_user.authorisations.last
        assert_equal @application, token.application
      end

      should "populate flash with access token details" do
        post :create, params: { api_user_id: @api_user, authorisation: { application_id: @application } }

        token = @api_user.authorisations.last
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

      should "record access token generated event" do
        @controller.stubs(:user_ip_address).returns("1.1.1.1")

        EventLog.expects(:record_event).with(
          @api_user,
          EventLog::ACCESS_TOKEN_GENERATED,
          initiator: @superadmin,
          application: @application,
          ip_address: "1.1.1.1",
        )

        post :create, params: { api_user_id: @api_user, authorisation: { application_id: @application } }
      end

      should "authorize access if AuthorisationPolicy#create? returns true" do
        policy = stub_everything("policy", create?: true).responds_like_instance_of(AuthorisationPolicy)
        AuthorisationPolicy.stubs(:new).returns(policy)

        assert_difference "Doorkeeper::AccessToken.count", 1 do
          post :create, params: { api_user_id: @api_user, authorisation: { application_id: @application } }
        end
      end

      should "not authorize access if AuthorisationPolicy#create? returns false" do
        policy = stub_everything("policy", create?: false).responds_like_instance_of(AuthorisationPolicy)
        AuthorisationPolicy.stubs(:new).returns(policy)

        post :create, params: { api_user_id: @api_user, authorisation: { application_id: @application } }

        assert_not_authorised
      end

      context "when creation fails" do
        setup do
          access_token = Doorkeeper::AccessToken.new
          access_token.stubs(:save).returns(false)
          authorisations = stub("authorisations", build: access_token)
          @api_user.stubs(:authorisations).returns(authorisations)
          ApiUser.stubs(:find).returns(@api_user)
        end

        should "do not add a 'signin' permission" do
          post :create, params: { api_user_id: @api_user, authorisation: { application_id: @application } }

          assert_not @api_user.has_access_to?(@application)
        end

        should "set flash error" do
          post :create, params: { api_user_id: @api_user, authorisation: { application_id: @application } }

          assert_equal "There was an error while creating the access token", flash[:error]
        end

        should "not record access token revoked event" do
          EventLog.expects(:record_event).never

          post :create, params: { api_user_id: @api_user, authorisation: { application_id: @application } }
        end
      end
    end

    context "signed in as Admin user" do
      setup do
        @admin = create(:admin_user)
        sign_in @admin

        @application = create(:application)
      end

      should "not be able to authorise API users" do
        post :create, params: { api_user_id: @api_user, authorisation: { application_id: @application } }

        assert_not_authorised
      end
    end

    context "not signed in" do
      setup do
        @application = create(:application)
      end

      should "not be allowed access" do
        post :create, params: { api_user_id: @api_user, authorisation: { application_id: @application } }

        assert_not_authenticated
      end
    end
  end

  context "POST revoke" do
    context "signed in as Superadmin user" do
      setup do
        @superadmin = create(:superadmin_user)
        sign_in @superadmin

        @access_token = create(:access_token, resource_owner_id: @api_user.id)
      end

      should "revoke access token" do
        post :revoke, params: { api_user_id: @api_user, id: @access_token }

        assert @access_token.reload.revoked?
      end

      should "redirect to manage tokens page" do
        post :revoke, params: { api_user_id: @api_user, id: @access_token }

        assert_redirected_to manage_tokens_api_user_path(@api_user)
      end

      should "set flash notice" do
        post :revoke, params: { api_user_id: @api_user, id: @access_token }

        assert_equal "Access for #{@access_token.application.name} was revoked", flash[:notice]
      end

      should "record access token revoked event" do
        @controller.stubs(:user_ip_address).returns("1.1.1.1")

        EventLog.expects(:record_event).with(
          @api_user,
          EventLog::ACCESS_TOKEN_REVOKED,
          initiator: @superadmin,
          application: @access_token.application,
          ip_address: "1.1.1.1",
        )

        post :revoke, params: { api_user_id: @api_user, id: @access_token }
      end

      should "authorize access if AuthorisationPolicy#revoke? returns true" do
        stub_policy(@superadmin, @access_token, policy_class: AuthorisationPolicy, revoke?: true)

        post :revoke, params: { api_user_id: @api_user, id: @access_token }

        assert @access_token.reload.revoked?
      end

      should "not authorize access if AuthorisationPolicy#revoke? returns false" do
        stub_policy(@superadmin, @access_token, policy_class: AuthorisationPolicy, revoke?: false)

        post :revoke, params: { api_user_id: @api_user, id: @access_token }

        assert_not_authorised
      end

      context "when revocation fails" do
        setup do
          @access_token.stubs(:revoke).returns(false)
          authorisations = stub("authorisations", find: @access_token)
          @api_user.stubs(:authorisations).returns(authorisations)
          ApiUser.stubs(:find).returns(@api_user)
        end

        should "set flash error" do
          post :revoke, params: { api_user_id: @api_user, id: @access_token }

          assert_equal "There was an error while revoking access for #{@access_token.application.name}", flash[:error]
        end

        should "not record access token revoked event" do
          EventLog.expects(:record_event).never

          post :revoke, params: { api_user_id: @api_user, id: @access_token }
        end
      end
    end

    context "signed in as Admin user" do
      setup do
        @admin = create(:admin_user)
        sign_in @admin

        @access_token = create(:access_token, resource_owner_id: @api_user.id)
      end

      should "not be able to revoke API user's authorisations" do
        post :revoke, params: { api_user_id: @api_user, id: @access_token }

        assert_not_authorised
      end
    end

    context "not signed in" do
      setup do
        @access_token = create(:access_token, resource_owner_id: @api_user.id)
      end

      should "not be allowed access" do
        post :revoke, params: { api_user_id: @api_user, id: @access_token }

        assert_not_authenticated
      end
    end
  end
end
