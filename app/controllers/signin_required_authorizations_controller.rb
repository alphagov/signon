class SigninRequiredAuthorizationsController < Doorkeeper::AuthorizationsController
  include Pundit
  EXPECTED_DOORKEEPER_VERSION = '4.2.6'

  def new
    if pre_auth.authorizable?
      if skip_authorization? || matching_token?
        if user_has_signin_permission_to_application?
          auth = authorization.authorize
          redirect_to auth.redirect_uri
        else
          session[:signin_missing_for_application] = application.try(:id)
          redirect_to signin_required_path
        end
      else
        render :new
      end
    else
      render :error
    end
  end

  def create
    if user_has_signin_permission_to_application?
      redirect_or_render authorization.authorize
    else
      session[:signin_missing_for_application] = application.try(:id)
      redirect_to signin_required_path
    end
  end

private

  def user_has_signin_permission_to_application?
    return false if application.nil?
    return false if current_resource_owner.nil?
    current_resource_owner.has_access_to?(application)
  end

  def application
    pre_auth.try(:client).try(:application)
  end
end
