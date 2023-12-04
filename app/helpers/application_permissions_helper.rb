module ApplicationPermissionsHelper
  def message_for_success(application_id)
    application = Doorkeeper::Application.find_by(id: application_id)
    return nil unless application

    additional_permissions = current_user.permissions_for(application).reject { |permission| permission == SupportedPermission::SIGNIN_NAME }

    if additional_permissions.any?
      paragraph = tag.p("You now have the following permissions for #{application.name}:", class: "govuk-body")
      list = tag.ul(class: "govuk-list govuk-list--bullet")
      additional_permissions.map { |permission| list << tag.li(permission) }
    else
      paragraph = tag.p("You can access #{application.name} but you do not have any additional permissions.", class: "govuk-body")
      list = nil
    end

    paragraph + list
  end
end
