# This file is overwritten at deploy-time from alphagov-deployment. At the time
# of writing, it isn't overwritten in production.

# Human-friendly name for this signon instance. This is used when generating
# reminder emails that need to disambiguate between instances.
if Rails.env.development? || Rails.env.test?
  Rails.application.config.instance_name = "development"
else
  Rails.application.config.instance_name = nil
end
