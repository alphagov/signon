class PrototypeController < ApplicationController
  skip_after_filter :verify_authorized
end
