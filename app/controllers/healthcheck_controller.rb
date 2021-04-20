class HealthcheckController < ApplicationController
  skip_after_action :verify_authorized

  def api_tokens
    render json: Healthcheck::ApiTokens.new.to_hash
  end
end
