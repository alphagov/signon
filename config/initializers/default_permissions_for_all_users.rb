Rails.application.config.after_initialize do
  def Signon.add_default_permission(app_name, permission_name)
    app = ::Doorkeeper::Application.find_by(name: app_name)
    if app.present?
      perm = app.supported_permissions.find_by(name: permission_name)
      if perm.present?
        Signon.default_permissions_for_all_users << perm
      else
        Rails.logger.warn("Attempting to add '#{permission_name}' for '#{app_name}' app as default permission but the permission is missing!")
      end
    else
      Rails.logger.warn("Attempting to add '#{permission_name}' for '#{app_name}' app as default permission but the app is missing!")
    end
  end
  Signon.default_permissions_for_all_users ||= []

  Signon.add_default_permission 'support', 'signin' unless Rails.env.test?
end
