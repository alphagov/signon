class Propagator
  def initialize(user, applications, updater, on_success)
    @user, @applications, @updater, @on_success = user, applications, updater, on_success
  end

  def attempt
    results = { successes: [], failures: [] }
    @applications.select(&:supports_push_updates?).each do |application|
      begin
        @updater.call(@user, application)
        results[:successes] << { application: application }
        @on_success.call(@user, application)
      rescue URI::InvalidURIError
        results[:failures] << { application: application, message: "Haven't got a valid URL for that app.", technical: "URL I have is: #{application.redirect_uri}" }
      rescue GdsApi::EndpointNotFound, SocketError => e
        results[:failures] << { application: application, message: "Couldn't find the app. Maybe the app is down?", technical: e.message }
      rescue GdsApi::TimedOutException
        results[:failures] << { application: application, message: "Timed out. Maybe the app is down?" }
      rescue GdsApi::HTTPErrorResponse => e
        message = case e.code
        when 502
          "Couldn't find the app. Maybe the app is down?"
        else
          e.message
        end
        results[:failures] << { application: application, message: message, technical: "HTTP status code was: #{e.code}" }
      rescue GdsApi::BaseError, StandardError => e
        results[:failures] << { application: application, message: "#{e.class.name}: #{e.message}" }
      end
    end
    results
  end
end
