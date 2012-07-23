require 'test_helper'

class PropagatePermissionsTest < ActiveSupport::TestCase

  def url_for_app(application)
    url = URI.parse(application.redirect_uri)
    "http://api:defined_on_rollout_not@#{url.host}/auth/gds/api/users/#{CGI.escape(@user.uid)}"
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
    request = stub_request(:put, url_for_app(@application)).with(body: expected_body)
    PropagatePermissions.new(@user, @user.permissions.map(&:application)).attempt
    assert_requested request
  end

  should "return a structure of successful and failed pushes" do
    user_not_in_database = FactoryGirl.create(:application, redirect_uri: "http://user-not-in-database.com/callback")
    FactoryGirl.create(:permission, 
                        application: user_not_in_database, 
                        user: @user, 
                        permissions: ["ba"])

    slow_app = FactoryGirl.create(:application, redirect_uri: "http://slow.com/callback")
    FactoryGirl.create(:permission, 
                        application: slow_app, 
                        user: @user, 
                        permissions: ["ba"])

    stub_request(:put, url_for_app(@application)).to_return(status: 200)
    stub_request(:put, url_for_app(user_not_in_database)).to_return(status: 404)
    stub_request(:put, url_for_app(slow_app)).to_timeout
  
    results = PropagatePermissions.new(@user, @user.permissions.map(&:application)).attempt

    assert_equal [{ application: @application }], results[:successes]
    expected_failures = [
      { 
        application: user_not_in_database, 
        message: "", 
        technical: "HTTP status code was: 404" 
      }, 
      { 
        application: slow_app, 
        message: "Timed out. Maybe the app is down?" 
      }
    ]
    assert_equal expected_failures, results[:failures]
  end

  context "successful update" do
    should "record the last_synced_at timestamp on the permission" do
      expected_body = @user.to_sensible_json
      
      stub_request(:put, url_for_app(@application)).with(body: expected_body)
      PropagatePermissions.new(@user, @user.permissions.map(&:application)).attempt
      assert_not_nil @permission.reload.last_synced_at
    end
  end

  context "failed update" do
    should "not record the last_synced_at timestamp on the permission" do
      expected_body = @user.to_sensible_json
      
      stub_request(:put, url_for_app(@application)).to_timeout
      PropagatePermissions.new(@user, @user.permissions.map(&:application)).attempt
      assert_nil @permission.reload.last_synced_at
    end
  end
end
