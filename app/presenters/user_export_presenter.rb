class UserExportPresenter
  include UsersHelper

  attr_reader :applications, :app_permissions

  def initialize(applications)
    @applications = applications

    permission_names = Hash[SupportedPermission.pluck(:id, :name)]

    @app_permissions = {}
    UserApplicationPermission.find_each do |permission|
      @app_permissions[permission.user_id] ||= {}
      @app_permissions[permission.user_id][permission.application_id] ||= []
      @app_permissions[permission.user_id][permission.application_id] << permission_names[permission.supported_permission_id]
    end
  end

  def header_row
    [
      "Name",
      "Email",
      "Role",
      "Organisation",
      "Sign-in count",
      "Last sign-in",
      "Created",
      "Status",
      "2SV Status",
    ].concat applications.map(&:name)
  end

  def row(user)
    [
      user.name,
      user.email,
      user.role.humanize,
      user.organisation.try(:name),
      user.sign_in_count,
      user.current_sign_in_at.try(:to_formatted_s, :db),
      user.created_at.try(:to_formatted_s, :db),
      user.status.humanize,
      two_step_status(user),
    ].concat(app_permissions_for(user))
  end

  def app_permissions_for(user)
    applications.map do |application|
      perms = app_permissions[user.id][application.id] if app_permissions[user.id]
      perms.sort.join(", ") if perms
    end
  end
end
