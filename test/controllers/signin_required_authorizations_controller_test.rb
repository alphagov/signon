require "test_helper"

class SigninRequiredAuthorizationsControllerTest < ActionController::TestCase
  def fragments(param)
    fragment = URI.parse(response.location).fragment
    Rack::Utils.parse_query(fragment)[param]
  end

  def translated_error_message(key)
    I18n.translate key, scope: %i[doorkeeper errors messages]
  end

  def default_scopes_exist(*scopes)
    Doorkeeper.configuration.stubs(default_scopes: Doorkeeper::OAuth::Scopes.from_array(scopes))
  end

  def auth_type_is_allowed(*grant_flows)
    Doorkeeper.configuration.stubs(grant_flows: grant_flows)
    # for some reason this value isn't being recalculated between tests
    # so we stub it too
    Doorkeeper.configuration.stubs(authorization_response_types: Doorkeeper.configuration.send(:calculate_authorization_response_types))
  end

  setup do
    @application = create(:application)
    @user = create(:user, with_signin_permissions_for: [@application])
    auth_type_is_allowed("implicit")
    @controller.stubs(current_resource_owner: @user)
  end

  test "warn if doorkeeper has been updated" do
    # We extracted SigninRequiredAuthorizationsController and its tests from
    # those for Doorkeeper::AuthorizationsController in version 4.2.6 it's very
    # possible that future versions of doorkeeper change the implementation or
    # tests and we should keep our versions up to date.  They may also have
    # introduced a better way for us to customise the behaviour.
    assert_equal SigninRequiredAuthorizationsController::EXPECTED_DOORKEEPER_VERSION, Doorkeeper::VERSION::STRING, "SigninRequiredAuthorizationsController was extracted from Doorkeeper::AuthorizationsController and has been checked against version #{SigninRequiredAuthorizationsController::EXPECTED_DOORKEEPER_VERSION} of the Gem.  It's now #{Doorkeeper::VERSION::STRING} so review the new version to check for updates."
  end

  context "POST #create" do
    setup do
      post :create, params: { client_id: @application.uid, response_type: "token", redirect_uri: @application.redirect_uri }
    end

    should "redirect after authorization" do
      assert_response :redirect
    end

    should "redirect to client redirect uri" do
      assert_redirected_to(/^#{@application.redirect_uri}/)
    end

    should "include access token in fragment" do
      assert_equal Doorkeeper::AccessToken.first.token, fragments("access_token")
    end

    should "include token type in fragment" do
      assert_equal "Bearer", fragments("token_type")
    end

    should "include token expiration in fragment" do
      assert_not_nil fragments("expires_in")
      assert fragments("expires_in").to_i >= 1.hour.to_i
    end

    should "issue the token for the current client" do
      assert_equal @application.id, Doorkeeper::AccessToken.first.application_id
    end

    should "issue the token for the current resource owner" do
      assert_equal @user.id, Doorkeeper::AccessToken.first.resource_owner_id
    end
  end

  context "POST #create with errors" do
    setup do
      default_scopes_exist :public
      post :create, params: { client_id: @application.uid, response_type: "token", scope: "invalid", redirect_uri: @application.redirect_uri }
    end

    should "redirect after authorization" do
      assert_response :redirect
    end

    should "redirect to client redirect uri" do
      assert_redirected_to(/^#{@application.redirect_uri}/)
    end

    should "not include access token in fragment" do
      assert_nil fragments("access_token")
    end

    should "include error in fragment" do
      assert_equal "invalid_scope", fragments("error")
    end

    should "include error description in fragment" do
      assert_equal translated_error_message(:invalid_scope), fragments("error_description")
    end

    should "not issue any access token" do
      assert Doorkeeper::AccessToken.all.empty?
    end
  end

  context "POST #create when the user does not have signin permission for the app" do
    setup do
      @user.application_permissions.where(supported_permission_id: @application.signin_permission).destroy_all
      @user.application_permissions.reload
      post :create, params: { client_id: @application.uid, response_type: "token", redirect_uri: @application.redirect_uri }
    end

    should "redirect after authorization" do
      assert_response :redirect
    end

    should "redirect to signin required error path" do
      assert_redirected_to signin_required_path
    end

    should "not issue any access token" do
      assert Doorkeeper::AccessToken.all.empty?
    end
  end

  context "POST #create with application already authorized" do
    setup do
      Doorkeeper.configuration.stubs(reuse_access_token: true)
      @access_token = create(:access_token, resource_owner_id: @user.id, application_id: @application.id)
      @access_token.save!
      post :create, params: { client_id: @application.uid, response_type: "token", redirect_uri: @application.redirect_uri }
    end

    should "returns the existing access token in a fragment" do
      assert_equal fragments("access_token"), @access_token.token
    end

    should "not creates a new access token" do
      assert_equal Doorkeeper::AccessToken.count, 1
    end
  end

  context "GET #new token request with native url and skip_authorization true" do
    setup do
      # technically redundant as this is our configuration anyway
      Doorkeeper.configuration.stubs(skip_authorization: ->(*_args) { true })
      @application.update_attribute :redirect_uri, "urn:ietf:wg:oauth:2.0:oob"
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

  context "GET #new code request with native url and skip_authorization true" do
    setup do
      auth_type_is_allowed "authorization_code"
      # technically redundant as this is our configuration anyway
      Doorkeeper.configuration.stubs(skip_authorization: ->(*_args) { true })
      @application.update_attribute :redirect_uri, "urn:ietf:wg:oauth:2.0:oob"
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

  context "GET #new with skip_authorization true" do
    setup do
      # technically redundant as this is our configuration anyway
      Doorkeeper.configuration.stubs(skip_authorization: ->(*_args) { true })
      get :new, params: { client_id: @application.uid, response_type: "token", redirect_uri: @application.redirect_uri }
    end

    should "redirect immediately" do
      assert_response :redirect
      assert_redirected_to(/^#{@application.redirect_uri}/)
    end

    should "issue a token" do
      assert_equal 1, Doorkeeper::AccessToken.count
    end

    should "include token type in fragment" do
      assert_equal "Bearer", fragments("token_type")
    end

    should "include token expiration in fragment" do
      assert_not_nil fragments("expires_in")
      assert fragments("expires_in").to_i >= 1.hour.to_i
    end

    should "issue the token for the current client" do
      assert_equal @application.id, Doorkeeper::AccessToken.first.application_id
    end

    should "issue the token for the current resource owner" do
      assert_equal @user.id, Doorkeeper::AccessToken.first.resource_owner_id
    end
  end

  context "GET #new with errors" do
    setup do
      default_scopes_exist :public
      get :new, params: { an_invalid: "request" }
    end

    should "not redirect" do
      assert_response :ok
    end

    should "not issue any token" do
      assert_equal 0, Doorkeeper::AccessGrant.count
      assert_equal 0, Doorkeeper::AccessToken.count
    end
  end

  context "GET #new with skip_authorization true when the user does not have signin permission for the app" do
    setup do
      @user.application_permissions.where(supported_permission_id: @application.signin_permission).destroy_all
      @user.application_permissions.reload
      # technically redundant as this is our configuration anyway
      Doorkeeper.configuration.stubs(skip_authorization: ->(*_args) { true })
      get :new, params: { client_id: @application.uid, response_type: "token", redirect_uri: @application.redirect_uri }
    end

    should "redirect after authorization" do
      assert_response :redirect
    end

    should "redirect to signin required error path" do
      assert_redirected_to signin_required_path
    end

    should "not issue any access token" do
      assert Doorkeeper::AccessToken.all.empty?
    end
  end
end
