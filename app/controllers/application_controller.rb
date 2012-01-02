require "slimmer/headers"

class ApplicationController < ActionController::Base
  include Slimmer::Headers
  protect_from_forgery
end
