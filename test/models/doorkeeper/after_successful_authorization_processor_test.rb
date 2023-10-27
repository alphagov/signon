require "test_helper"

class Doorkeeper::AfterSuccessfulAuthorizationProcessorTest < ActiveSupport::TestCase
  context "#process" do
    setup do
      @controller = Doorkeeper::TokensController.new
      @user = create(:user)
      @application = create(:application)
      token = create(:access_token, application: @application, resource_owner_id: @user.id)
      token_response = Doorkeeper::OAuth::TokenResponse.new(token)
      @context = Doorkeeper::OAuth::Hooks::Context.new(auth: token_response)
    end

    should "log a SUCCESSFUL_USER_APPLICATION_AUTHORIZATION event" do
      EventLog.expects(:record_event).with(@user, EventLog::SUCCESSFUL_USER_APPLICATION_AUTHORIZATION, application: @application)

      Doorkeeper::AfterSuccessfulAuthorizationProcessor.new(@controller, @context).process
    end

    context "when the controller is not an instance of Doorkeeper::TokensController" do
      setup do
        @controller = Object.new
      end

      should "not log a SUCCESSFUL_USER_APPLICATION_AUTHORIZATION event" do
        EventLog.expects(:record_event).never

        Doorkeeper::AfterSuccessfulAuthorizationProcessor.new(@controller, @context).process
      end
    end

    context "when the application does not exist" do
      setup do
        @application.destroy
      end

      should "not log a SUCCESSFUL_USER_APPLICATION_AUTHORIZATION event" do
        EventLog.expects(:record_event).never

        Doorkeeper::AfterSuccessfulAuthorizationProcessor.new(@controller, @context).process
      end
    end

    context "when the user does not exist" do
      setup do
        @user.destroy
      end

      should "not log a SUCCESSFUL_USER_APPLICATION_AUTHORIZATION event" do
        EventLog.expects(:record_event).never

        Doorkeeper::AfterSuccessfulAuthorizationProcessor.new(@controller, @context).process
      end
    end
  end
end
