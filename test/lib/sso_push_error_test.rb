require "test_helper"
require "gds_api/base"

class SSOPushErrorTest < ActiveSupport::TestCase
  def setup
    @user = create(:user)
    @application = create(:application, redirect_uri: "https://app.com/callback", with_non_delegatable_supported_permissions: %w[user_update_permission])
  end

  context "rescuing GdsApi::HTTPErrorResponse" do
    should "add application name and response error code to exception message" do
      ex = GdsApi::HTTPErrorResponse.new(504)
      SSOPushClient.any_instance.stubs(:post_json).raises(ex)

      exception = assert_raise(SSOPushError) do
        SSOPushClient.new(@application).reauth_user(@user.uid)
      end
      assert_equal "Error pushing to #{@application.name}, got response 504", exception.message
    end
  end

  context "rescuing other GdsApi errors" do
    should "add application name and error message to exception message" do
      ex = GdsApi::TimedOutException.new
      SSOPushClient.any_instance.stubs(:post_json).raises(ex)

      exception = assert_raise(SSOPushError) do
        SSOPushClient.new(@application).reauth_user(@user.uid)
      end
      assert_equal "Error pushing to #{@application.name}. Timeout connecting to application.", exception.message
    end
  end

  context "rescuing StandardError" do
    should "add application name and message to exception message" do
      ex = StandardError.new
      SSOPushClient.any_instance.stubs(:post_json).raises(ex)

      exception = assert_raise(SSOPushError) do
        SSOPushClient.new(@application).reauth_user(@user.uid)
      end
      assert_equal "Error pushing to #{@application.name}. StandardError", exception.message
    end
  end
end
