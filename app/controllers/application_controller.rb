require 'devise/hooks/two_step_verification'

class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery

  include Devise::Helpers::PasswordExpirable
  include TwoStepVerificationHelper

  before_action :handle_two_step_verification
  after_filter :verify_authorized, unless: :devise_controller?

  before_filter do
    headers['X-Frame-Options'] = 'SAMEORIGIN'
  end

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def after_sign_in_path_for(resource)
    if resource.prompt_for_2sv?
      prompt_two_step_verification_path
    else
      super
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  def current_resource_owner
    User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
  end

  private

  def user_not_authorized(exception)
    flash[:alert] = "You do not have permission to perform this action."
    redirect_to root_path
  end

  def redirect_to_prior_flow(args = {})
    redirect_to stored_location_for(:user) || :root, args
  end

  def store_full_location_for(resource_or_scope, location)
    session_key = stored_location_key_for(resource_or_scope)
    uri = parse_uri(location)
    if uri && uri.host =~ %r{\.#{Plek.new.parent_domain}$}
      session[session_key] = uri.to_s
    else
      session[session_key] = root_path
    end
  end
end
