# Human-friendly name for this signon instance. This is used when generating
# reminder emails that need to disambiguate between instances.
Rails.application.config.instance_name = if Rails.env.development? || Rails.env.test?
                                           "development"
                                         else
                                           ENV.fetch("INSTANCE_NAME", nil)
                                         end
