require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  def change_user_password(user_factory, new_password)
    original_password = "I am a very original password. Refrigerator weevil."
    user = create(user_factory, password: original_password)
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
      user, orig_password = change_user_password(:user, 'destabilizers842}orthophosphate')

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

  context "GET edit" do
    context "changing an email" do
      setup do
        @user = create(:user_with_pending_email_change)
        sign_in @user
      end

      should "show the unconfirmed_email" do
        get :edit

        assert_select "input#user_unconfirmed_email[value=#{@user.unconfirmed_email}]"
      end
    end
  end

  context "PUT update" do
    setup do
      @user = create(:user, email: "old@email.com")
      sign_in @user
    end

    context "changing an email" do
      should "stage the change, and send a confirmation email" do
        put :update, user: { email: "new@email.com" }

        @user.reload
        assert_equal "new@email.com", @user.unconfirmed_email
        assert_equal "old@email.com", @user.email

        email = ActionMailer::Base.deliveries.last
        assert_equal "Confirm your email change", email.subject
        assert_equal "new@email.com", email.to[0]
      end
    end
  end

  context "PUT resend_email_change" do
    should "send an email change confirmation email" do
      @user = create(:user_with_pending_email_change)
      sign_in @user
      put :resend_email_change

      assert_equal "Confirm your email change", ActionMailer::Base.deliveries.last.subject
    end

    should "use a new token if it's expired" do
      @user = create(:user_with_pending_email_change,
                                          confirmation_token: "old token",
                                          confirmation_sent_at: 15.days.ago)
      sign_in @user
      put :resend_email_change, id: @user.id

      assert_not_equal "old token", @user.reload.confirmation_token
    end
  end

  context "DELETE cancel_email_change" do
    setup do
      @user = create(:user_with_pending_email_change)
      sign_in @user
    end

    should "clear the unconfirmed_email and the confirmation_token" do
      delete :cancel_email_change, id: @user.id

      @user.reload
      assert_equal nil, @user.unconfirmed_email
      assert_equal nil, @user.confirmation_token
    end
  end

  context "GET show (as OAuth client application)" do
    should "fetching json profile with a valid oauth token should succeed" do
      user = create(:user)
      application = create(:application)
      permission = create(:permission, user_id: user.id, application_id: application.id)
      token = create(:access_token, :application => application, :resource_owner_id => user.id)

      @request.env['HTTP_AUTHORIZATION'] = "Bearer #{token.token}"
      get :show, {:format => :json}

      assert_equal "200", response.code
      presenter = UserOAuthPresenter.new(user, application)
      assert_equal presenter.as_hash.to_json, response.body
    end

    should "fetching json profile with an invalid oauth token should not succeed" do
      user = create(:user)
      application = create(:application)
      token = create(:access_token, :application => application, :resource_owner_id => user.id)

      @request.env['HTTP_AUTHORIZATION'] = "Bearer #{token.token.sub(/[0-9]/, 'x')}"
      get :show, {:format => :json}

      assert_equal "401", response.code
    end

    should "fetching json profile without any bearer header should not succeed" do
      get :show, {:format => :json}
      assert_equal "401", response.code
    end

    should "fetching json profile should include permissions" do
      application = create(:application)
      user = create(:user, with_signin_permissions_for: [ application ])
      token = create(:access_token, :application => application, :resource_owner_id => user.id)

      @request.env['HTTP_AUTHORIZATION'] = "Bearer #{token.token}"
      get :show, {:format => :json}
      json = JSON.parse(response.body)
      assert_equal(["signin"], json['user']['permissions'])
    end

    should "fetching json profile should include only permissions for the relevant app" do
      application, other_application = create_pair(:application)
      user = create(:user, with_signin_permissions_for: [ application, other_application ])

      token = create(:access_token, :application => application, :resource_owner_id => user.id)

      @request.env['HTTP_AUTHORIZATION'] = "Bearer #{token.token}"
      get :show, {:format => :json}
      json = JSON.parse(response.body)
      assert_equal(["signin"], json['user']['permissions'])
    end

    should "fetching json profile should update last_synced_at for the relevant app" do
      user = create(:user)
      application = create(:application)
      permission = create(:permission, user_id: user.id, application_id: application.id)
      token = create(:access_token, :application => application, :resource_owner_id => user.id)

      @request.env['HTTP_AUTHORIZATION'] = "Bearer #{token.token}"
      get :show, {:format => :json}

      assert_not_nil permission.reload.last_synced_at
    end

    should "fetching json profile should succeed even if no permission for relevant app" do
      user = create(:user)
      application = create(:application)
      token = create(:access_token, :application => application, :resource_owner_id => user.id)

      @request.env['HTTP_AUTHORIZATION'] = "Bearer #{token.token}"
      get :show, {:format => :json}

      assert_response :ok
    end
  end
end
