module ApplicationTableHelper
  def update_permissions_link(application, user)
    unless application.sorted_supported_permissions_grantable_from_ui(include_signin: false).empty?
      link_to(edit_api_user_application_permissions_path(user, application), class: "govuk-link") do
        safe_join(
          ["Update permissions",
           content_tag(:span, " for #{application.name}", class: "govuk-visually-hidden")],
        )
      end
    end
  end
end
