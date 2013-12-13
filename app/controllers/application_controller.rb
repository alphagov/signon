class ApplicationController < ActionController::Base
  protect_from_forgery
  check_authorization unless: :devise_controller?

  before_filter do
    headers['X-Frame-Options'] = 'SAMEORIGIN'
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: "You do not have permission to perform this action."
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  def current_resource_owner
    User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
  end

  def current_ability
    "Abilities::#{current_user.role.classify}".constantize.new(current_user) if current_user
  end

end
