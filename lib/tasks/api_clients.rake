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
    permission = application.supported_permissions.find_by_name!(args[:permission])

    # create as user
    default_password = SecureRandom.urlsafe_base64
    user = User.create!(
      name: args[:name],
      password: default_password,
      password_confirmation: default_password,
      email: args[:email]
    )

    # Grant authorisation and permissions
    user.permissions.create!(application: application, permissions: [permission.name])

    # The application attribute is attr_protected, hence this form of setting it.
    authorisation = user.authorisations.build(expires_in: 10.years.to_i)
    authorisation.application = application
    authorisation.save!

    puts "User created: user.name <#{user.name}>"
    puts "              user.email <#{user.email}>"
    puts "Access token: #{authorisation.token}"
  end

  desc "Grants the signon user the correct permissions for syncing to each app"
  task :ensure_signon_user_app_permissions, [:signon_user_email] => :environment do |t, args|
    PERMISSIONS_TO_GRANT = ["update_user_permission"]

    email = args[:signon_user_email]
    unless email.present?
      raise "The email of the signon sync user must be provided to run this task."
    end

    user = User.find_by_email(email)
    unless user.present?
      raise "A user does not exist with the email '#{email}', exiting"
    end

    applications = Doorkeeper::Application.all

    applications.each do |application|
      print "#{application.name}:\n"

      if user.authorisations.where(application_id: application.id).any?
        print "    authorisation already exists\n"
      else
        user.authorisations.create(application_id: application.id, expires_in: 10.years)
        print "    created authorisation\n"
      end

      app_permissions = user.permissions.where(application_id: application.id).first
      if app_permissions.present?
        if PERMISSIONS_TO_GRANT & app_permissions.permissions == PERMISSIONS_TO_GRANT
          print "    permissions already exist\n"
        else
          app_permissions.permissions = app_permissions.permissions | PERMISSIONS_TO_GRANT
          app_permissions.save!
          print "    update permissions: #{app_permissions.permissions.join(', ')}\n"
        end
      else
        app_permissions = user.permissions.create!(application: application, permissions: PERMISSIONS_TO_GRANT)
        print "    grant new permissions: #{app_permissions.permissions.join(', ')}\n"
      end
    end
  end
end
