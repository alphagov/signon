require 'sso_push_error'

module Signon
  module ExceptionHandler
    def with_exception_handling
      yield
    rescue URI::InvalidURIError
      raise SSOPushError.new(@application, message: "Invalid URL for application.")
    rescue GdsApi::EndpointNotFound, SocketError => e
      raise SSOPushError.new(@application, message: "Couldn't find the application. Maybe the application is down?")
    rescue Errno::ETIMEDOUT, Timeout::Error, GdsApi::TimedOutException
      raise SSOPushError.new(@application, message: "Timeout connecting to application.")
    rescue GdsApi::HTTPErrorResponse => e
      raise SSOPushError.new(@application, response_code: e.code)
    rescue *network_errors, StandardError => e
      raise SSOPushError.new(@application, message: e.message)
    end

    def network_errors
      [SocketError, Errno::ECONNREFUSED, Errno::EHOSTDOWN, Errno::EHOSTUNREACH]
    end
  end
end
