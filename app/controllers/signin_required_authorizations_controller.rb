class SigninRequiredAuthorizationsController < Doorkeeper::AuthorizationsController
  include Pundit
  EXPECTED_DOORKEEPER_VERSION = "5.3.2".freeze

  def new
    if pre_authorizable?
      if skip_authorization? || matching_token?
        if user_has_signin_permission_to_application?
          auth = authorize_response
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
      super
    else
      session[:signin_missing_for_application] = application.try(:id)
      redirect_to signin_required_path
    end
  end

private

  def pre_authorizable?
    @pre_authorizable ||= pre_auth.authorizable?
  end

  def user_has_signin_permission_to_application?
    return false if application.nil?
    return false if current_resource_owner.nil?

    current_resource_owner.has_access_to?(application)
  end

  def application
    pre_authorizable? # Doorkeeper PreAuthorization controller must be validated in-order for the client to be instantiated.
    pre_auth.try(:client).try(:application)
  end
end
