require "test_helper"

class OauthUsersControllerTest < ActionController::TestCase
  context "GET show (as OAuth client application)" do
    setup do
      @application = create(:application)
    end

    should "fetching json profile with a valid oauth token should succeed" do
      user = create(:user)
      user.grant_application_signin_permission(@application)
      token = create(:access_token, application: @application, resource_owner_id: user.id)

      @request.env["HTTP_AUTHORIZATION"] = "Bearer #{token.token}"
      get :show, params: { client_id: @application.uid, format: :json }

      assert_equal "200", response.code
      presenter = UserOAuthPresenter.new(user, @application)
      assert_equal presenter.as_hash.to_json, response.body
    end

    should "fetching json profile with a valid oauth token, but no client_id should succeed" do
      # For now.  Once gds-sso is updated everywhere, this will 401.

      user = create(:user)
      user.grant_application_signin_permission(@application)
      token = create(:access_token, application: @application, resource_owner_id: user.id)

      @request.env["HTTP_AUTHORIZATION"] = "Bearer #{token.token}"
      get :show, params: { format: :json }

      assert_equal "200", response.code
      presenter = UserOAuthPresenter.new(user, @application)
      assert_equal presenter.as_hash.to_json, response.body
    end

    should "fetching json profile with an invalid oauth token should not succeed" do
      user = create(:user)
      token = create(:access_token, application: @application, resource_owner_id: user.id)

      @request.env["HTTP_AUTHORIZATION"] = "Bearer #{token.token.sub(/[0-9]/, 'x')}"
      get :show, params: { client_id: @application.uid, format: :json }

      assert_equal "401", response.code
    end

    should "fetching json profile with a token for another app should not succeed" do
      other_application = create(:application)
      user = create(:user)
      token = create(:access_token, application: other_application, resource_owner_id: user.id)

      @request.env["HTTP_AUTHORIZATION"] = "Bearer #{token.token.sub(/[0-9]/, 'x')}"
      get :show, params: { client_id: @application.uid, format: :json }

      assert_equal "401", response.code
    end

    should "fetching json profile without any bearer header should not succeed" do
      get :show, params: { client_id: @application.uid, format: :json }
      assert_equal "401", response.code
    end

    should "fetching json profile should include permissions" do
      user = create(:user, with_signin_permissions_for: [@application])
      token = create(:access_token, application: @application, resource_owner_id: user.id)

      @request.env["HTTP_AUTHORIZATION"] = "Bearer #{token.token}"
      get :show, params: { client_id: @application.uid, format: :json }
      json = JSON.parse(response.body)
      assert_equal([SupportedPermission::SIGNIN_NAME], json["user"]["permissions"])
    end

    should "fetching json profile should include only permissions for the relevant app" do
      other_application = create(:application)
      user = create(:user, with_signin_permissions_for: [@application, other_application])

      token = create(:access_token, application: @application, resource_owner_id: user.id)

      @request.env["HTTP_AUTHORIZATION"] = "Bearer #{token.token}"
      get :show, params: { client_id: @application.uid, format: :json }
      json = JSON.parse(response.body)
      assert_equal([SupportedPermission::SIGNIN_NAME], json["user"]["permissions"])
    end

    should "fetching json profile should update last_synced_at for the relevant app" do
      user = create(:user)
      user.grant_application_signin_permission(@application)
      token = create(:access_token, application: @application, resource_owner_id: user.id)

      @request.env["HTTP_AUTHORIZATION"] = "Bearer #{token.token}"
      get :show, params: { client_id: @application.uid, format: :json }

      assert_not_nil user.application_permissions.first.last_synced_at
    end

    should "fetching json profile should fail if no signin permission for relevant app" do
      user = create(:user)
      token = create(:access_token, application: @application, resource_owner_id: user.id)

      @request.env["HTTP_AUTHORIZATION"] = "Bearer #{token.token}"
      get :show, params: { client_id: @application.uid, format: :json }

      assert_response :unauthorized
    end
  end
end
