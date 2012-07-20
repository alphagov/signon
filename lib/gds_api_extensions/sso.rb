require 'gds_api/base'

class GdsApi::SSO < GdsApi::Base
  def initialize(options)
    super(nil, options)
  end

  def update_user(user)
    put_json!("#{base_url}/user", JSON.parse(user))
  end

  private
    def base_url
      "#{@endpoint}/auth/gds/api"
    end
end