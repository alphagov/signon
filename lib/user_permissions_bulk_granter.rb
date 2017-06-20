class UserPermissionsBulkGranter
  attr_reader :application
  def initialize(application_name)
    @application = ::Doorkeeper::Application.find_by(name: application_name)
    raise "No such application: '#{application_name}'" if @application.nil?
  end

  def grant(permission_name)
    permission = application.supported_permissions.find_by(name: permission_name)
    raise "No such permission: '#{permission_name}' for application: '#{application.name}'" if permission.nil?
    User.includes(application_permissions: :supported_permission).find_each do |user|
      unless user.eager_loaded_permission_for(application).include? permission.name
        user.application_permissions.create!(supported_permission_id: permission.id)
      end
    end
  end
end
