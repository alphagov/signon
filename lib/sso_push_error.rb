class SSOPushError < StandardError
  def initialize(application, uid, details = {})
    @application, @uid, @details = application, uid, details
  end

  def message
    message = "Error pushing to #{@application.name} for user with uid #{@uid}"
    message += ", got response #{@details[:response_code]}" if @details[:response_code]
    message += ". #{@details[:message]}" if @details[:message]
    message
  end
end
