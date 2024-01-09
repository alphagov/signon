class SigninRequiredAuthorizationsController < Doorkeeper::AuthorizationsController
  layout "admin_layout"

  include Pundit::Authorization
  # This controller was based on (and inherits from)
  # https://github.com/doorkeeper-gem/doorkeeper/blob/main/app/controllers/doorkeeper/authorizations_controller.rb
  #
  # Future doorkeeper changes may result in test failures in this controller.
  # If you see a failure after upgrading the Doorkeeper gem, then check the
  # doorkeeper version of this controller for any changes that may need to be ported here.

  def new
    if pre_authorizable?
      if user_has_signin_permission_to_application?
        auth = authorize_response
        redirect_to auth.redirect_uri, allow_other_host: true
      else
        session[:signin_missing_for_application] = application.try(:id)
        redirect_to signin_required_path
      end
    else
      render :error
    end
  end

  def create
    render plain: "Not found", status: :not_found
  end

  def destroy
    render plain: "Not found", status: :not_found
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
