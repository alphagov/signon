class PropagatePermissions
  def initialize(user, applications)
    @user = user
    @applications = applications
  end

  def attempt
    results = { successes: [], failures: [] }
    @applications.each do |application|
      begin
        update_application(@user, application)
        results[:successes] << { application: application }
      rescue URI::InvalidURIError
        results[:failures] << { application: application, message: "Haven't got a valid URL for that app.", technical: "URL I have is: #{application.redirect_uri}" }
      rescue GdsApi::EndpointNotFound, SocketError => e
        results[:failures] << { application: application, message: "Couldn't find the app. Maybe the app is down?", technical: e.message }
      rescue GdsApi::TimedOutException
        results[:failures] << { application: application, message: "Timed out. Maybe the app is down?" }
      rescue GdsApi::HTTPErrorResponse => e
        message = case e.code
        when 404
          "This app doesn't seem to support syncing of permissions."
        when 502
          "Couldn't find the app. Maybe the app is down?"
        else
          e.message
        end
        results[:failures] << { application: application, message: message, technical: "HTTP status code was: #{e.code}" }
      rescue GdsApi::BaseError, StandardError => e
        results[:failures] << { application: application, message: e.message }
      end
    end
    results
  end

  private
    def update_application(user, application)
      options = { endpoint_url: application.url_without_path }.merge(GDS_API_CREDENTIALS)
      api = GdsApi::SSO.new(options)    
      api.update_user(user.to_sensible_json)
    end
end
