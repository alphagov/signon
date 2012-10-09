# This is the host that statsd exists on.
#
# Statsd "the process" listens on a port on the provided host for UDP
# messages. Given that it's UDP, it's fire-and-forget and will not
# block your application. You do not need to have a statsd process
# running locally on your development environment.
STATSD_HOST = "localhost"
STATSD_PREFIX = ENV['GOVUK_STATSD_PREFIX']
