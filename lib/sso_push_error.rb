class SSOPushError < StandardError
  def initialize(application, details = {})
    @application, @details = application, details
  end

  def message
    message = "Error pushing to #{@application.name}"
    message += ", got response #{@details[:response_code]}" if @details[:response_code]
    message += ". #{@details[:message]}" if @details[:message]
    message
  end
end
