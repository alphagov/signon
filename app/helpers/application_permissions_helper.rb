module ApplicationPermissionsHelper
  def permissions_updated_description(application_id, user = current_user)
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

  def notice_about_non_delegatable_permissions(current_user, application, other_grantee = nil)
    return nil if current_user.govuk_admin?
    return nil unless application.has_non_delegatable_non_signin_permissions_grantable_from_ui?

    link = if other_grantee
             link_to(
               "view all the permissions #{other_grantee.name} has for #{application.name}",
               user_application_permissions_path(other_grantee, application),
               class: "govuk-link",
             )
           else
             link_to(
               "view all the permissions you have for #{application.name}",
               account_application_permissions_path(application),
               class: "govuk-link",
             )
           end

    "Below, you will only see permissions that you are authorised to manage. You can also #{link}.".html_safe
  end
end
