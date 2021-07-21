class SSOPushError < StandardError
  def initialize(application, details = {})
    message = "Error pushing to #{application.name}"
    message += ", got response #{details[:response_code]}" if details[:response_code]
    message += ". #{details[:message]}" if details[:message]

    super(message)
  end
end
