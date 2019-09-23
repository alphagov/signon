require "test_helper"

class AuthoriseApplicationTest < ActionDispatch::IntegrationTest
  setup do
    @app = create(:application, name: "MyApp")
    @user = create(:user, with_signin_permissions_for: [@app])
  end

  context "when the user is flagged for 2SV" do
    setup do
      @user.update_attribute(:require_2sv, true)
      ignoring_spurious_error do
        visit "/oauth/authorize?response_type=code&client_id=#{@app.uid}&redirect_uri=#{@app.redirect_uri}"
      end
      signin_with(@user, set_up_2sv: false)
    end

    should "not confirm the authorisation" do
      assert_response_contains("Make your account more secure")
    end
  end

  should "not confirm the authorisation until the user signs in" do
    visit "/oauth/authorize?response_type=code&client_id=#{@app.uid}&redirect_uri=#{@app.redirect_uri}"
    refute Doorkeeper::AccessGrant.find_by(resource_owner_id: @user.id)

    ignoring_spurious_error do
      signin_with(@user)
    end

    assert_redirected_to_application @app
    # check the access grant has really been created
    assert_kind_of Doorkeeper::AccessGrant, Doorkeeper::AccessGrant.find_by(resource_owner_id: @user.id)
  end

  should "not confirm the authorisation if the user has not passed 2-step verification" do
    @user.update_attribute(:otp_secret_key, ROTP::Base32.random_base32)

    visit "/"
    signin_with(@user, second_step: false)
    ignoring_spurious_error do
      visit "/oauth/authorize?response_type=code&client_id=#{@app.uid}&redirect_uri=#{@app.redirect_uri}"
    end
    assert_response_contains("get your code")
    refute Doorkeeper::AccessGrant.find_by(resource_owner_id: @user.id)
  end

  should "not confirm the authorisation if the user does not have 'signin' permission for the application" do
    @user.application_permissions.where(supported_permission_id: @app.signin_permission).destroy_all

    visit "/"
    signin_with(@user)
    ignoring_spurious_error do
      visit "/oauth/authorize?response_type=code&client_id=#{@app.uid}&redirect_uri=#{@app.redirect_uri}"
    end
    assert_response_contains("You don’t have permission to sign in to #{@app.name}.")
    refute Doorkeeper::AccessGrant.find_by(resource_owner_id: @user.id)
  end

  should "confirm the authorisation for a signed-in user with 'signin' permission to the app" do
    visit "/"
    signin_with(@user)
    ignoring_spurious_error do
      visit "/oauth/authorize?response_type=code&client_id=#{@app.uid}&redirect_uri=#{@app.redirect_uri}"
    end

    assert_redirected_to_application @app
    assert_kind_of Doorkeeper::AccessGrant, Doorkeeper::AccessGrant.find_by(resource_owner_id: @user.id)
  end

  should "confirm the authorisation for a fully authenticated 2SV user" do
    @user.update_attribute(:otp_secret_key, ROTP::Base32.random_base32)

    visit "/"
    signin_with(@user)
    ignoring_spurious_error do
      visit "/oauth/authorize?response_type=code&client_id=#{@app.uid}&redirect_uri=#{@app.redirect_uri}"
    end

    assert_redirected_to_application @app
    assert_kind_of Doorkeeper::AccessGrant, Doorkeeper::AccessGrant.find_by(resource_owner_id: @user.id)
  end

  def assert_redirected_to_application(app)
    assert_match /^#{app.redirect_uri}/, current_url
    assert_match /\?code=/, current_url
  end

  def ignoring_spurious_error
    # During testing, requests for all domains get routed to Signon;
    # including the capybara browser being redirected to other apps.
    # The browser gets a redirect to url of the destination app.
    # This then gets routed to Signon but Signon doesn't know how to handle the route.
    # And so it raises the RoutingError
    begin
      yield
    rescue ActionController::RoutingError
    end
  end
end
