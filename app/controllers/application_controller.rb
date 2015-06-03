class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery

  after_filter :verify_authorized, unless: :devise_controller?

  before_filter do
    headers['X-Frame-Options'] = 'SAMEORIGIN'
  end

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

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

end
