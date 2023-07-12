require "test_helper"

class AuthoriseApplicationTest < ActionDispatch::IntegrationTest
  setup do
    @app = create(:application, name: "MyApp")
    @user = create(:user, with_signin_permissions_for: [@app])
  end

  context "when the user has had 2SV mandated" do
    setup do
      @user.update!(require_2sv: true)
      visit "/oauth/authorize?response_type=code&client_id=#{@app.uid}&redirect_uri=#{@app.redirect_uri}"
      signin_with(@user, set_up_2sv: false)
    end

    should "not confirm the authorisation" do
      assert_response_contains("Make your account more secure")
    end
  end

  should "not confirm the authorisation until the user signs in" do
    visit "/oauth/authorize?response_type=code&client_id=#{@app.uid}&redirect_uri=#{@app.redirect_uri}"
    assert_not Doorkeeper::AccessGrant.find_by(resource_owner_id: @user.id)

    ignoring_requests_to_redirect_uri(@app) do
      signin_with(@user)
    end

    assert_redirected_to_application @app
    # check the access grant has really been created
    assert_access_granted @user
  end

  should "not confirm the authorisation if the user has not passed 2-step verification" do
    @user.update!(otp_secret_key: ROTP::Base32.random_base32)

    visit "/"
    signin_with(@user, second_step: false)
    visit "/oauth/authorize?response_type=code&client_id=#{@app.uid}&redirect_uri=#{@app.redirect_uri}"

    assert_response_contains("Enter 6-digit code")
    assert_not Doorkeeper::AccessGrant.find_by(resource_owner_id: @user.id)
  end

  should "not confirm the authorisation if the user does not have 'signin' permission for the application" do
    @user.application_permissions.where(supported_permission_id: @app.signin_permission).destroy_all

    visit "/"
    signin_with(@user)
    visit "/oauth/authorize?response_type=code&client_id=#{@app.uid}&redirect_uri=#{@app.redirect_uri}"

    assert_response_contains("You don’t have permission to sign in to #{@app.name}.")
    assert_not Doorkeeper::AccessGrant.find_by(resource_owner_id: @user.id)
  end

  should "confirm the authorisation for a signed-in user with 'signin' permission to the app" do
    visit "/"
    signin_with(@user)
    ignoring_requests_to_redirect_uri(@app) do
      visit "/oauth/authorize?response_type=code&client_id=#{@app.uid}&redirect_uri=#{@app.redirect_uri}"
    end

    assert_redirected_to_application @app
    assert_access_granted @user
  end

  should "confirm the authorisation for a fully authenticated 2SV user" do
    @user.update!(otp_secret_key: ROTP::Base32.random_base32)

    visit "/"
    signin_with(@user)
    ignoring_requests_to_redirect_uri(@app) do
      visit "/oauth/authorize?response_type=code&client_id=#{@app.uid}&redirect_uri=#{@app.redirect_uri}"
    end

    assert_redirected_to_application @app
    assert_access_granted @user
  end

  def assert_redirected_to_application(app)
    assert_match(/^#{app.redirect_uri}/, current_url)
    assert_match(/\?code=/, current_url)
  end

  def assert_access_granted(user)
    assert_kind_of Doorkeeper::AccessGrant, Doorkeeper::AccessGrant.find_by(resource_owner_id: user.id)
  end

  def ignoring_requests_to_redirect_uri(app)
    # During testing, requests for all domains get routed to Signon;
    # including the request for the redirect_uri of the oauth application.
    # The path of this redirect_uri doesn't exist in the Signon app
    # so we catch and swallow the exception raised when this request is
    # made.

    yield
  rescue ActionController::RoutingError => e
    redirect_uri_path = URI.parse(app.redirect_uri).path
    raise e unless e.message == "No route matches [GET] \"#{redirect_uri_path}\""
  end
end
