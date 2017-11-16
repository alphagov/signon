class PrototypeController < ApplicationController
  skip_after_action :verify_authorized
end
