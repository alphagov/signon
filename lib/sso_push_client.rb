require "gds_api/base"
require "exception_handler"

class SSOPushClient < GdsApi::Base
  include ExceptionHandler

  def initialize(application)
    @application = application
    super(application.url_without_path, bearer_token: SSOPushCredential.credentials(application))
  end

  def update_user(uid, user)
    with_exception_handling do
      put_json("#{base_url}/users/#{CGI.escape(uid)}", user)
    end
  end

  def reauth_user(uid)
    with_exception_handling do
      post_json("#{base_url}/users/#{CGI.escape(uid)}/reauth", {})
    end
  end

private

  def base_url
    "#{@endpoint}/auth/gds/api"
  end
end
