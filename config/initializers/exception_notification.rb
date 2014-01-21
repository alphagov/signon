require 'exception_notification/rails'

ExceptionNotification.configure do |config|
  config.add_notifier :email, {
    :email_prefix => "[#{Rails.application.class.parent_name}] ",
    :sender_address => %{"Winston Smith-Churchill" <winston@alphagov.co.uk>},
    :exception_recipients => %w{govuk-exceptions@digital.cabinet-office.gov.uk}
  }
end
