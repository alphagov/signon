class Api::V1::ApiController < ApplicationController
  include AdminApiHelper

  before_action :authenticate

  skip_after_action :verify_authorized
  protect_from_forgery with: :null_session

  rescue_from ActionController::ParameterMissing, with: :missing_params_error
  rescue_from ActiveRecord::RecordInvalid, with: :not_valid_error
  rescue_from ActiveRecord::RecordNotFound, with: :not_found_error

  respond_to :json
end
