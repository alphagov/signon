module ApplicationPermissionsHelper
  def message_for_success(application_id, user = current_user)
    application = Doorkeeper::Application.find_by(id: application_id)
    return nil unless application

    additional_permissions = user.permissions_for(application).reject { |permission| permission == SupportedPermission::SIGNIN_NAME }

    if additional_permissions.any?
      prefix = user == current_user ? "You now have" : "#{user.name} now has"
      paragraph = tag.p("#{prefix} the following permissions for #{application.name}:", class: "govuk-body")
      list = tag.ul(class: "govuk-list govuk-list--bullet")
      additional_permissions.map { |permission| list << tag.li(permission) }
    else
      string = if user == current_user
                 "You can access #{application.name} but you do not have any additional permissions."
               else
                 "#{user.name} can access #{application.name} but does not have any additional permissions."
               end
      paragraph = tag.p(string, class: "govuk-body")
      list = nil
    end

    paragraph + list
  end
end
