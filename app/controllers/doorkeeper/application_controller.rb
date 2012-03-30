# Need to load because in development mode this file gets re-evaluated on every request and a require
# would only load the parent app controller on the first request.
load Doorkeeper::Engine.config.root.join 'app', 'controllers', 'doorkeeper', 'application_controller.rb'

Doorkeeper::ApplicationController.class_eval do
  before_filter do
    headers["X-Slimmer-Skip"] = "1"
  end
end