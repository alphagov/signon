unless Rails.env.development? or Rails.env.test?
  Calendars::Application.config.middleware.use ExceptionNotifier,
    :email_prefix => "[Calendars] ",
    :sender_address => %{"Winston Smith-Churchill" <winston@alphagov.co.uk>},
    :exception_recipients => %w{govuk-dev@digital.cabinet-office.gov.uk}
end