Doorkeeper.configure do
  # This block will be called to check whether the
  # resource owner is authenticated or not
  resource_owner_authenticator do |_routes|
    # Put your resource owner authentication logic here.
    # If you want to use named routes from your app you need
    # to call them on routes object eg.
    # routes.new_user_session_path
    user = current_user || warden.authenticate!(scope: :user)
    if user.need_two_step_verification? && warden.session(:user)["need_two_step_verification"]
      redirect_to new_two_step_verification_session_path
    elsif user.prompt_for_2sv?
      redirect_to prompt_two_step_verification_path
    else
      user
    end
  end

  # If you want to restrict the access to the web interface for
  # adding oauth authorized applications you need to declare the
  # block below
  admin_authenticator do |_routes|
    # Prevent all access to admin web interface, only allow application management
    # from command line
    render text: "Access denied", status: 403
  end

  # Access token expiration time (default 2 hours)
  access_token_expires_in 2.hours

  # Issue access tokens with refresh token (disabled by default)
  use_refresh_token

  # Define access token scopes for your provider
  # For more information go to https://github.com/applicake/doorkeeper/wiki/Using-Scopes
  # authorization_scopes do
  #   scope :public, :default => true, :description => "The public one"
  #   scope :write,  :description => "Updating information"
  # end

  # Under some circumstances you might want to have applications auto-approved,
  # so that the user skips the authorization step.
  # For example if dealing with trusted a application.
  skip_authorization do |_resource_owner, _client|
    true
  end
end
