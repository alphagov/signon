require 'test_helper'

class SuspensionUpdaterTest < ActiveSupport::TestCase
    def url_for_app(application)
    url = URI.parse(application.redirect_uri)
    "http://api:defined_on_rollout_not@#{url.host}/auth/gds/api/users/#{CGI.escape(@user.uid)}/reauth"
  end

  setup do
    @user = FactoryGirl.create(:user)
    @application = FactoryGirl.create(:application, redirect_uri: "http://app.com/callback")
  end

  should "send an empty POST to the app" do
    request = stub_request(:post, url_for_app(@application)).with(body: "{}")
    SuspensionUpdater.new(@user, [@application]).attempt
    assert_requested request
  end

  should "return a structure of successful and failed pushes" do
    user_not_in_database = FactoryGirl.create(:application, redirect_uri: "http://user-not-in-database.com/callback")
    slow_app = FactoryGirl.create(:application, redirect_uri: "http://slow.com/callback")

    stub_request(:post, url_for_app(@application)).to_return(status: 200)
    stub_request(:post, url_for_app(user_not_in_database)).to_return(status: 404)
    stub_request(:post, url_for_app(slow_app)).to_timeout
  
    results = SuspensionUpdater.new(@user, ::Doorkeeper::Application.all).attempt

    assert_equal [{ application: @application }], results[:successes]
    expected_failures = [
      { 
        application: user_not_in_database, 
        message: "GdsApi::HTTPNotFound",
        technical: "HTTP status code was: 404" 
      }, 
      { 
        application: slow_app, 
        message: "Timed out. Maybe the app is down?" 
      }
    ]
    assert_equal expected_failures, results[:failures]
  end
end
