require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  def change_user_password(user_factory, new_password)
    original_password = "I am a very original password. Refrigerator weevil."
    user = FactoryGirl.create(user_factory, password: original_password)
    original_password_hash = user.encrypted_password
    sign_in user

    post :update_passphrase, {
      user: {
        current_password: original_password,
        password: new_password,
        password_confirmation: new_password
      }
    }

    return user, original_password_hash
  end

  context "PUT update_passphrase" do
    should "changing passwords to something strong should succeed" do
      user, orig_password = change_user_password(:user, 'a new strong p4ssw0rd')

      assert_equal "302", response.code
      assert_equal root_url, response.location

      user.reload
      assert_not_equal orig_password, user.encrypted_password
    end

    should "changing password to something too short should fail" do
      user, orig_password = change_user_password(:user, 'short')

      assert_equal "200", response.code
      assert_match "too short", response.body

      user.reload
      assert_equal orig_password, user.encrypted_password
    end

    should "changing password to something too weak should fail" do
      user, orig_password = change_user_password(:user, 'zymophosphate')

      assert_equal "200", response.code
      assert_match "not strong enough", response.body

      user.reload
      assert_equal orig_password, user.encrypted_password
    end
  end

  context "GET show (as OAuth client application)" do
    should "fetching json profile with a valid oauth token should succeed" do
      user = FactoryGirl.create(:user)
      application = FactoryGirl.create(:application)
      permission = FactoryGirl.create(:permission, user_id: user.id, application_id: application.id)
      token = FactoryGirl.create(:access_token, :application => application, :resource_owner_id => user.id)

      @request.env['HTTP_AUTHORIZATION'] = "Bearer #{token.token}"
      get :show, {:format => :json}

      assert_equal "200", response.code
      assert_equal user.to_sensible_json(application), response.body
    end

    should "fetching json profile with an invalid oauth token should not succeed" do
      user = FactoryGirl.create(:user)
      application = FactoryGirl.create(:application)
      token = FactoryGirl.create(:access_token, :application => application, :resource_owner_id => user.id)

      @request.env['HTTP_AUTHORIZATION'] = "Bearer #{token.token.sub(/[0-9]/, 'x')}"
      get :show, {:format => :json}

      assert_equal "401", response.code
    end

    should "fetching json profile without any bearer header should not succeed" do
      get :show, {:format => :json}
      assert_equal "401", response.code
    end

    should "fetching json profile should include permissions" do
      user = FactoryGirl.create(:user)
      application = FactoryGirl.create(:application)
      permission = FactoryGirl.create(:permission, user_id: user.id, application_id: application.id)
      token = FactoryGirl.create(:access_token, :application => application, :resource_owner_id => user.id)

      @request.env['HTTP_AUTHORIZATION'] = "Bearer #{token.token}"
      get :show, {:format => :json}
      json = JSON.parse(response.body)
      assert_equal({ application.name => ["signin"] }, json['user']['permissions'])
    end

    should "fetching json profile should include only permissions for the relevant app" do
      user = FactoryGirl.create(:user)
      application = FactoryGirl.create(:application)
      other_application = FactoryGirl.create(:application)
      permission = FactoryGirl.create(:permission, user_id: user.id, application_id: application.id)
      other_permission = FactoryGirl.create(:permission, user_id: user.id, application_id: other_application.id)
      token = FactoryGirl.create(:access_token, :application => application, :resource_owner_id => user.id)

      @request.env['HTTP_AUTHORIZATION'] = "Bearer #{token.token}"
      get :show, {:format => :json}
      json = JSON.parse(response.body)
      assert_equal({ application.name => ["signin"] }, json['user']['permissions'])
    end

    should "fetching json profile should update last_synced_at for the relevant app" do
      user = FactoryGirl.create(:user)
      application = FactoryGirl.create(:application)
      permission = FactoryGirl.create(:permission, user_id: user.id, application_id: application.id)
      token = FactoryGirl.create(:access_token, :application => application, :resource_owner_id => user.id)

      @request.env['HTTP_AUTHORIZATION'] = "Bearer #{token.token}"
      get :show, {:format => :json}
      
      assert_not_nil permission.reload.last_synced_at
    end

    should "fetching json profile should succeed even if no permission for relevant app" do
      user = FactoryGirl.create(:user)
      application = FactoryGirl.create(:application)
      token = FactoryGirl.create(:access_token, :application => application, :resource_owner_id => user.id)

      @request.env['HTTP_AUTHORIZATION'] = "Bearer #{token.token}"
      get :show, {:format => :json}

      assert_response :ok
    end
  end
end
