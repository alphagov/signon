namespace :api_clients do
  desc "Create an API client for a registered application"
  task :create, [:name, :email, :application_name, :permission] => :environment do |t, args|
    # create as user
    default_password = SecureRandom.urlsafe_base64
    user = User.create!(
      name: args[:name],
      password: default_password,
      password_confirmation: default_password,
      email: args[:email]
    )

    application = Doorkeeper::Application.find_by_name!(args[:application_name])

    # Ensure the permission exists
    permission = application.supported_permissions.find_by_name!(args[:permission])

    # Grant authorisation and permissions
    user.permissions.create!(application: application, permissions: [permission.name])
    authorisation = user.authorisations.create!(application: application, expires_in: 10.years.to_i)
    
    puts "User created: user.name <#{user.name}>"
    puts "              user.email <#{user.email}>"
    puts "Access token: #{authorisation.token}"
  end
end