module AccountApplicationsHelper
  def message_for_success(application_id)
    application = Doorkeeper::Application.find(application_id)

    paragraph = tag.p("You now have the following permissions for #{application.name}:", class: "govuk-body")
    list = tag.ul(class: "govuk-list govuk-list--bullet")

    current_user
      .permissions_for(application)
      .reject { |permission| permission == SupportedPermission::SIGNIN_NAME }
      .map { |permission| list << tag.li(permission) }

    paragraph + list
  end
end
