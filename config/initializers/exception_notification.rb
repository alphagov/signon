if Rails.env.development? or Rails.env.test?
  Rails.application.config.middleware.use ExceptionNotifier,
    :email_prefix => "[Signon] ",
    :sender_address => %{"notifier" <notifier@example.com>},
    :exception_recipients => %w{exceptions@example.com}
else
  Rails.application.config.middleware.use ExceptionNotifier,
    :email_prefix => "[#{Rails.application.to_s.split('::').first}] ",
    :sender_address => %{"Winston Smith-Churchill" <winston@alphagov.co.uk>},
    :exception_recipients => %w{govuk-exceptions@digital.cabinet-office.gov.uk}
end