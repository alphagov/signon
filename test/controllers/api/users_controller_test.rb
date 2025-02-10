require "test_helper"

class Api::UsersControllerTest < ActionController::TestCase
  setup do
    @application = create(:application)
  end

  context "as admin user" do
    setup do
      @admin = create(:admin_user)
      sign_in @admin
    end

    should "not be able to access the API endpoint" do
      get :index

      assert_equal "401", response.code
    end
  end

  context "in development environment" do
    setup do
      Rails.env.stubs(:development?).returns(true)
    end

    should "be able to access the API endpoint" do
      get :index

      assert_equal "200", response.code
    end
  end

  context "as a user with a valid token" do
    setup do
      @user = create(:user, name: "Signon API")
      @user.grant_application_signin_permission(@application)
      @token = create(:access_token, application: @application, resource_owner_id: @user.id)

      @request.env["HTTP_AUTHORIZATION"] = "Bearer #{@token.token}"
    end

    should "return users with given UUIDs" do
      user1 = create(:user, uid: SecureRandom.uuid)
      _user2 = create(:user, uid: SecureRandom.uuid)
      user3 = create(:user, uid: SecureRandom.uuid)

      get :index, params: {
        format: :json,
        uuids: [user1.uid, user3.uid],
      }

      assert_equal "200", response.code

      body = JSON.parse(response.body).map(&:deep_symbolize_keys)

      assert_equal body.length, 2
      assert_equal body[0], Api::UserPresenter.present(user1)
      assert_equal body[1], Api::UserPresenter.present(user3)
    end

    should "return an empty array when no users are found" do
      get :index, params: {
        format: :json,
        uuids: [SecureRandom.uuid],
      }

      assert_equal "200", response.code

      body = JSON.parse(response.body).map(&:deep_symbolize_keys)

      assert_equal body.length, 0
    end
  end

  context "with an invalid token" do
    setup do
      @request.env["HTTP_AUTHORIZATION"] = "Bearer FAKE_BEARER_TOKEN"
    end

    should "not succeed" do
      get :index, params: {
        format: :json,
        uuids: [SecureRandom.uuid],
      }

      assert_equal "401", response.code
    end
  end

  context "with a valid bearer token for another application" do
    setup do
      other_application = create(:application)
      @user = create(:user)
      @user.grant_application_signin_permission(@application)
      @token = create(:access_token, application: other_application, resource_owner_id: @user.id)

      @request.env["HTTP_AUTHORIZATION"] = "Bearer #{@token.token}"
    end

    should "not succeed" do
      get :index, params: {
        format: :json,
        uuids: [SecureRandom.uuid],
      }

      assert_equal "401", response.code
    end
  end
end
