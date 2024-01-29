module ApplicationTableHelper
  include Pundit::Authorization

  def update_permissions_link(application, user = nil)
    link_path = if user.nil?
                  edit_account_application_permissions_path(application)
                elsif user.api_user?
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

  def view_permissions_link(application, user = nil)
    link_path = if user
                  user_application_permissions_path(user, application)
                else
                  account_application_permissions_path(application)
                end

    link_to(link_path, class: "govuk-link") do
      safe_join(
        ["View permissions",
         content_tag(:span, " for #{application.name}", class: "govuk-visually-hidden")],
      )
    end
  end

  def remove_access_link(application, user = nil)
    link_path = if user
                  delete_user_application_signin_permission_path(user, application)
                else
                  delete_account_application_signin_permission_path(application)
                end

    link_to(
      link_path,
      class: "govuk-button govuk-button--warning govuk-!-margin-0",
      data: { module: "govuk-button" },
    ) do
      safe_join(["Remove access", content_tag(:span, " to #{application.name}", class: "govuk-visually-hidden")])
    end
  end

  def account_applications_permissions_link(application)
    if policy([:account, application]).edit_permissions?
      update_permissions_link(application)
    elsif policy([:account, application]).view_permissions?
      view_permissions_link(application)
    end
  end
end
