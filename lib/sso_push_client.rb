require 'gds_api/base'
require 'sso_push_error'

class SSOPushClient < GdsApi::Base
  def initialize(application)
    @application = application
    super(application.url_without_path, bearer_token: SSOPushCredential.credentials(application))
  end

  def update_user(uid, user)
    @uid = uid
    with_exception_handling do
      put_json!("#{base_url}/users/#{CGI.escape(uid)}", user)
    end
  end

  def reauth_user(uid)
    @uid = uid
    with_exception_handling do
      post_json!("#{base_url}/users/#{CGI.escape(uid)}/reauth", {})
    end
  end

  private
    def base_url
      "#{@endpoint}/auth/gds/api"
    end

    def with_exception_handling
      yield
    rescue URI::InvalidURIError
      raise SSOPushError.new(@application, @uid, message: "Invalid URL for application.")
    rescue GdsApi::EndpointNotFound, SocketError => e
      raise SSOPushError.new(@application, @uid, message: "Couldn't find the application. Maybe the application is down?")
    rescue Errno::ETIMEDOUT, Timeout::Error, GdsApi::TimedOutException
      raise SSOPushError.new(@application, @uid, message: "Timeout connecting to application.")
    rescue GdsApi::HTTPErrorResponse => e
      raise SSOPushError.new(@application, @uid, response_code: e.code)
    rescue *network_errors, StandardError => e
      raise SSOPushError.new(@application, @uid, message: e.message)
    end

    def network_errors
      [SocketError, Errno::ECONNREFUSED, Errno::EHOSTDOWN, Errno::EHOSTUNREACH]
    end

end
