module Doorkeeper
  class AfterSuccessfulAuthorizationProcessor
    def initialize(controller, context)
      @controller = controller
      @context = context
    end

    def process
      return unless @controller.instance_of?(Doorkeeper::TokensController)
      return unless application && user

      EventLog.record_event(user, EventLog::SUCCESSFUL_USER_APPLICATION_AUTHORIZATION, application:)
    end

  private

    def token
      @context.auth.token
    end

    def application
      Doorkeeper::Application.find_by(id: token.application_id)
    end

    def user
      User.find_by(id: token.resource_owner_id)
    end
  end
end
