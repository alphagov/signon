require 'test_helper'

class PropagatePermissionsTest < ActiveSupport::TestCase

  def url_for_app(application)
    url = URI.parse(application.redirect_uri)
    "http://api:defined_on_rollout_not@#{url.host}/auth/gds/api/user"
  end

  setup do
    @user = FactoryGirl.create(:user)
    @application = FactoryGirl.create(:application, redirect_uri: "http://app.com/callback")
    @permission = FactoryGirl.create(:permission, 
                                      application: @application, 
                                      user: @user, 
                                      permissions: ["ba"])
  end

  should "send a PUT to the related app with the user.json as in the OAuth exchange" do
    expected_body = @user.to_sensible_json
    expected_url = 
    request = stub_request(:put, url_for_app(@application)).with(body: expected_body)
    PropagatePermissions.new([@permission]).attempt
    assert_requested request
  end

  should "return a structure of successful and failed pushes" do
    not_supported_yet_app = FactoryGirl.create(:application, redirect_uri: "http://not-supported-yet.com/callback")
    FactoryGirl.create(:permission, 
                        application: not_supported_yet_app, 
                        user: @user, 
                        permissions: ["ba"])

    slow_app = FactoryGirl.create(:application, redirect_uri: "http://slow.com/callback")
    FactoryGirl.create(:permission, 
                        application: slow_app, 
                        user: @user, 
                        permissions: ["ba"])

    stub_request(:put, url_for_app(@application)).to_return(status: 200)
    stub_request(:put, url_for_app(not_supported_yet_app)).to_return(status: 404)
    stub_request(:put, url_for_app(slow_app)).to_timeout
  
    results = PropagatePermissions.new(@user.permissions).attempt

    assert_equal [{ application: @application }], results[:successes]
    expected_failures = [
      { 
        application: not_supported_yet_app, 
        message: "This app doesn't seem to support syncing of permissions.", 
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
