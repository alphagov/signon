require "test_helper"

class SigninRequiredAuthorizationsControllerTest < ActionController::TestCase
  def default_scopes_exist(*scopes)
    Doorkeeper.configuration.stubs(default_scopes: Doorkeeper::OAuth::Scopes.from_array(scopes))
  end

  def auth_type_is_allowed(*grant_flows)
    Doorkeeper.configuration.stubs(grant_flows:)
    # for some reason this value isn't being recalculated between tests
    # so we stub it too
    Doorkeeper.configuration.stubs(authorization_response_flows: Doorkeeper.configuration.grant_flows.map { |name| Doorkeeper::GrantFlow.get(name) })
    Doorkeeper.configuration.stubs(authorization_response_types: Doorkeeper.configuration.grant_flows.map { |name| Doorkeeper::GrantFlow.get(name).response_type_matches })
  end

  setup do
    @application = create(:application)
    @user = create(:user, with_signin_permissions_for: [@application])
    @controller.stubs(current_resource_owner: @user)
  end

  context "POST #create" do
    should "return 404" do
      post :create
      assert_response :not_found
    end
  end

  context "GET #new token request with native url" do
    setup do
      auth_type_is_allowed "implicit"
      @application.update! redirect_uri: "urn:ietf:wg:oauth:2.0:oob"
      get :new, params: { client_id: @application.uid, response_type: "token", redirect_uri: @application.redirect_uri }
    end

    should "redirect immediately" do
      assert_response :redirect
      assert_redirected_to(/oauth\/token\/info\?access_token=/)
    end

    should "not issue a grant" do
      assert_equal 0, Doorkeeper::AccessGrant.count
    end

    should "issue a token" do
      assert_equal 1, Doorkeeper::AccessToken.count
    end
  end

  context "GET #new code request with native url" do
    setup do
      auth_type_is_allowed "authorization_code"
      @application.update! redirect_uri: "urn:ietf:wg:oauth:2.0:oob"
      get :new, params: { client_id: @application.uid, response_type: "code", redirect_uri: @application.redirect_uri }
    end

    should "redirect immediately" do
      assert_response :redirect
      assert_redirected_to(/oauth\/authorize\//)
    end

    should "issue a grant" do
      assert_equal 1, Doorkeeper::AccessGrant.count
    end

    should "not issue a token" do
      assert_equal 0, Doorkeeper::AccessToken.count
    end
  end

  context "GET #new" do
    setup do
      auth_type_is_allowed "authorization_code"
      get :new, params: { client_id: @application.uid, response_type: "code", redirect_uri: @application.redirect_uri }
    end

    should "redirect immediately" do
      assert_response :redirect
      assert_redirected_to(/^#{@application.redirect_uri}/)
    end

    should "issue a grant" do
      assert_equal 1, Doorkeeper::AccessGrant.count
    end

    should "not issue a token" do
      assert_equal 0, Doorkeeper::AccessToken.count
    end
  end

  context "GET #new with errors" do
    setup do
      auth_type_is_allowed "authorization_code"
      default_scopes_exist :public
      get :new, params: { an_invalid: "request" }
    end

    should "not redirect" do
      assert_response :ok
    end

    should "not issue a grant" do
      assert_equal 0, Doorkeeper::AccessGrant.count
    end

    should "not issue a token" do
      assert_equal 0, Doorkeeper::AccessToken.count
    end
  end

  context "GET #new when the user does not have signin permission for the app" do
    setup do
      auth_type_is_allowed "authorization_code"
      @user.application_permissions.where(supported_permission_id: @application.signin_permission).destroy_all
      @user.application_permissions.reload
      get :new, params: { client_id: @application.uid, response_type: "code", redirect_uri: @application.redirect_uri }
    end

    should "redirect after authorization" do
      assert_response :redirect
    end

    should "redirect to signin required error path" do
      assert_redirected_to signin_required_path
    end

    should "not issue a grant" do
      assert_equal 0, Doorkeeper::AccessGrant.count
    end

    should "not issue a token" do
      assert_equal 0, Doorkeeper::AccessToken.count
    end
  end
end
