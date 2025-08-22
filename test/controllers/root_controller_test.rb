require "test_helper"

class RootControllerTest < ActionController::TestCase
  def setup
    create(:application, name: "Support")
  end

  test "visiting root#accessibility_statement should succeed" do
    get :accessibility_statement
    assert_equal "200", response.code
  end

  test "visiting root#index should require authentication" do
    get :index
    assert_equal "302", response.code
    assert_equal new_user_session_url, response.location
  end

  test "visiting root#index as a signed-in user should succeed" do
    sign_in create(:user)
    get :index
    assert_equal "200", response.code
  end

  test "root#index should strip sensitive query parameters from analytics" do
    sign_in create(:user)
    get :index
    assert_equal "200", response.code
    meta_tags = css_select 'meta[name="govuk:ga4-strip-query-string-parameters"]'
    assert_equal 1, meta_tags.length
    meta_tag = meta_tags.first
    assert_equal "reset_password_token,invitation_token", meta_tag["content"]
  end

  test "sets the X-Frame-Options header to SAMEORIGIN" do
    sign_in create(:user)
    get :index
    assert_equal "SAMEORIGIN", response.header["X-Frame-Options"]
  end

  test "Your applications should include apps you have permission to signin to" do
    exclusive_app = create(:application, name: "Exclusive app")
    everybody_app = create(:application, name: "Everybody app")
    user = create(:user, with_permissions: { exclusive_app => [], everybody_app => [SupportedPermission::SIGNIN_NAME] })

    sign_in user

    get :index

    assert_select "h3", "Everybody app"
    assert_select "h3", count: 1
  end

  test "do not display application with no home URI on dashboard even if you have signin permission" do
    application = create(:application, name: "App without home page", home_uri: nil)
    user = create(:user, with_signin_permissions_for: [application])
    sign_in user

    get :index

    assert_select "h3", text: "App without home page", count: 0
  end

  test "do not display retired application on dashboard even if you have signin permission" do
    application = create(:application, name: "Retired app", retired: true)
    user = create(:user, with_signin_permissions_for: [application])
    sign_in user

    get :index

    assert_select "h3", text: "Retired app", count: 0
  end

  test "do not display API-only application on dashboard even if you have signin permission" do
    application = create(:application, name: "API-only app", api_only: true)
    user = create(:user, with_signin_permissions_for: [application])
    sign_in user

    get :index

    assert_select "h3", text: "API-only app", count: 0
  end

  test "GDS publishers should be told to ask their delivery manager when they don't have permission to use a publishing app" do
    gds = create(:organisation, content_id: "af07d5a5-df63-4ddc-9383-6a666845ebe9")
    gds_user = create(:user, organisation: gds)
    session[:signin_missing_for_application] = create(:application, name: "Everybody app").id
    sign_in gds_user
    get :signin_required

    assert_select "h1", "You don’t have permission to sign in to Everybody app."
    assert_select "p", "Ask your delivery manager if you need access."
  end

  test "Departmental publishers should be told to ask their GOV.UK contact when they don't have permission to use a publishing app" do
    session[:signin_missing_for_application] = create(:application, name: "Whitehall").id
    sign_in create(:user_in_organisation)
    get :signin_required

    assert_select "h1", "You don’t have permission to sign in to Whitehall."
    assert_select "p", "Ask your organisation’s main GOV.UK contact if you need access."
  end

  test "Departmental publishers should be told they don't have permissions to use GDS only applications" do
    session[:signin_missing_for_application] = create(:application, name: "Publisher").id
    sign_in create(:user_in_organisation)
    get :signin_required

    assert_select "h1", "You don’t have permission to use this app."
    assert_select "p", count: 0
  end
end
