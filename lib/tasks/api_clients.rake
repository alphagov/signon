namespace :api_clients do
  # Used to register an API client (API clients are just a type of user),
  # grant them a given named permission in a named application,
  # authorize them and create an appropriate token for use as a Bearer
  # token.
  #
  # Parameters:
  #    name - A friendly name for the "user"
  #      (eg. "frontend application")
  #    email - An email address for contact about that app
  #      (eg. frontend@mydomain.com)
  #    application_name - The *name* used for the app within signonotron
  #      (eg. 'Panopticon')
  #    permission - The *name* of the default permission to be granted
  #      (eg. 'signin')
  desc "Create an API client for a registered application"
  task :create, [:name, :email, :application_name, :permission] => :environment do |t, args|
    # make sure we have all the pieces
    application = Doorkeeper::Application.find_by_name!(args[:application_name])
    unless application.supported_permission_strings.include? args[:permission]
      raise ArgumentError, "Unsupported permission '#{args[:permission]}'"
    end

    # create as user
    default_password = SecureRandom.urlsafe_base64
    user = User.new(
      name: args[:name],
      password: default_password,
      password_confirmation: default_password,
      email: args[:email]
    )
    user.api_user = true
    user.save!

    # Grant authorisation and permissions
    user.permissions.create!(application: application, permissions: [args[:permission]])

    # The application attribute is attr_protected, hence this form of setting it.
    authorisation = user.authorisations.build(expires_in: 10.years.to_i)
    authorisation.application = application
    authorisation.save!

    puts "User created: user.name <#{user.name}>"
    puts "              user.email <#{user.email}>"
    puts "Access token: #{authorisation.token}"
  end
end
