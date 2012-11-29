require 'gds_api/base'

class SSOPushClient < GdsApi::Base
  def initialize(application)
    super(application.url_without_path, GDS_API_CREDENTIALS)
  end

  def update_user(uid, user)
    put_json!("#{base_url}/users/#{CGI.escape(uid)}", user)
  end

  def reauth_user(uid)
    post_json!("#{base_url}/users/#{CGI.escape(uid)}/reauth", {})
  end

  private
    def base_url
      "#{@endpoint}/auth/gds/api"
    end
end
