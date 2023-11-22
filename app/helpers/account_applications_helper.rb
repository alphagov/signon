module AccountApplicationsHelper
  def message_for_success(application_id, user: current_user)
    application = Doorkeeper::Application.find_by(id: application_id)
    return nil unless application

    additional_permissions = user.permissions_for(application).reject { |permission| permission == SupportedPermission::SIGNIN_NAME }

    if additional_permissions.any?
      if user == current_user
        paragraph = tag.p("You now have the following permissions for #{application.name}:", class: "govuk-body")
      else
        paragraph = tag.p("#{user.name} now has the following permissions for #{application.name}:", class: "govuk-body")
      end
      list = tag.ul(class: "govuk-list govuk-list--bullet")
      additional_permissions.map { |permission| list << tag.li(permission) }
    else
      paragraph = tag.p("You can access #{application.name} but you do not have any additional permissions.", class: "govuk-body")
      list = nil
    end

    paragraph + list
  end
end
