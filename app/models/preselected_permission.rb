class PreselectedPermission
  PRESELECTED_PERMISSIONS = [
    { application_name: "Asset Manager", permission: SupportedPermission::SIGNIN_NAME },
    { application_name: "Content Data", permission: SupportedPermission::SIGNIN_NAME },
    { application_name: "Content Preview", permission: SupportedPermission::SIGNIN_NAME },
    { application_name: "GovSearch", permission: SupportedPermission::SIGNIN_NAME },
    { application_name: "Maslow", permission: SupportedPermission::SIGNIN_NAME },
    { application_name: "Support", permission: "feedex" },
  ].freeze

  def self.permissions
    permissions = PRESELECTED_PERMISSIONS.map do |preselected_permission|
      application = Doorkeeper::Application.where(name: preselected_permission[:application_name]).first
      next unless application

      SupportedPermission.find_by(application_id: application.id, name: preselected_permission[:permission])
    end

    permissions.reject(&:nil?)
  end
end
