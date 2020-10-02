require "devise/hooks/two_step_verification"

class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery with: :exception

  include TwoStepVerificationHelper

  before_action :handle_two_step_verification
  after_action :verify_authorized, unless: :devise_controller?

  before_action do
    headers["X-Frame-Options"] = "SAMEORIGIN"
  end

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from Notifications::Client::BadRequestError, with: :notify_bad_request

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  def current_resource_owner
    @_current_resource_owner ||= User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
  end

  def application_making_request
    @_application_making_request ||= ::Doorkeeper::Application.find(doorkeeper_token.application_id) if doorkeeper_token
  end

private

  def user_ip_address
    request.remote_ip
  end

  def doorkeeper_authorize!
    original_return_value = super
    return original_return_value if api_user_via_token_has_signin_permission_on_app?

    # The following code is a distillation of the error path of
    # doorkeeper_authorize! from Doorkeeper::Rails::Helpers which is the
    # super version called above.
    options = doorkeeper_unauthorized_render_options
    status = :unauthorized
    if options.blank?
      head status
    else
      options[:status] = status
      options[:layout] = false if options[:layout].nil?
      render options
    end
    original_return_value
  end

  def api_user_via_token_has_signin_permission_on_app?
    current_resource_owner && application_making_request && current_resource_owner.has_access_to?(application_making_request)
  end

  def user_not_authorized(_exception)
    flash[:alert] = "You do not have permission to perform this action."
    redirect_to root_path
  end

  def notify_bad_request(_exception)
    render plain: "Error: One or more recipients not in GOV.UK Notify team (code: 400)", status: :bad_request
  end

  def redirect_to_prior_flow(args = {})
    redirect_to stored_location_for("2sv") || :root, args
  end
end
