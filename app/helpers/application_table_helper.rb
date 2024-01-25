module ApplicationTableHelper
  def update_permissions_link(application, user)
    link_path = if user.api_user?
                  edit_api_user_application_permissions_path(user, application)
                else
                  edit_user_application_permissions_path(user, application)
                end

    unless application.sorted_supported_permissions_grantable_from_ui(include_signin: false).empty?
      link_to(link_path, class: "govuk-link") do
        safe_join(
          ["Update permissions",
           content_tag(:span, " for #{application.name}", class: "govuk-visually-hidden")],
        )
      end
    end
  end
end
