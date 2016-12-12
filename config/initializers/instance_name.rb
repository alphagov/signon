# Human-friendly name for this signon instance. This is used when generating
# reminder emails that need to disambiguate between instances.
if Rails.env.development? || Rails.env.test?
  Rails.application.config.instance_name = "development"
else
  Rails.application.config.instance_name = ENV.fetch("INSTANCE_NAME", nil)
end
