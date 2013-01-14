Doorkeeper.configure do
  # This block will be called to check whether the
  # resource owner is authenticated or not
  resource_owner_authenticator do |routes|
    # Put your resource owner authentication logic here.
    # If you want to use named routes from your app you need
    # to call them on routes object eg.
    # routes.new_user_session_path
    current_user || warden.authenticate!(:scope => :user)
  end

  # If you want to restrict the access to the web interface for
  # adding oauth authorized applications you need to declare the
  # block below
  admin_authenticator do |routes|
    # Prevent all access to admin web interface, only allow application management 
    # from command line
    render :text => "Access denied", :status => 403
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
  skip_authorization do |resource_owner, client|
    true
  end
end
