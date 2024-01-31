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

    if application.sorted_supported_permissions_grantable_from_ui(include_signin: false).any?
      link_to(link_path, class: "govuk-link") do
        safe_join(
          ["Update permissions",
           content_tag(:span, " for #{application.name}", class: "govuk-visually-hidden")],
        )
      end
    else
      ""
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
    else
      ""
    end
  end

  def users_applications_permissions_link(application, user)
    if policy(UserApplicationPermission.for(user, application)).edit?
      update_permissions_link(application, user)
    else
      view_permissions_link(application, user)
    end
  end

  def users_applications_remove_access_link(application, user)
    if policy(UserApplicationPermission.for(user, application)).delete?
      remove_access_link(application, user)
    else
      ""
    end
  end

  def account_applications_remove_access_link(application)
    if policy([:account, application]).remove_signin_permission?
      remove_access_link(application)
    else
      ""
    end
  end

  def grant_access_link(application, user = nil)
    link_path = if user
                  user_application_signin_permission_path(user, application)
                else
                  account_application_signin_permission_path(application)
                end

    button_to(
      link_path,
      class: "govuk-button govuk-!-margin-0",
      data: { module: "govuk-button" },
    ) do
      safe_join(["Grant access", content_tag(:span, " to #{application.name}", class: "govuk-visually-hidden")])
    end
  end

  def users_applications_grant_access_link(application, user)
    if policy(UserApplicationPermission.for(user, application)).create?
      grant_access_link(application, user)
    else
      ""
    end
  end

  def account_applications_grant_access_link(application)
    if policy([:account, Doorkeeper::Application]).grant_signin_permission?
      grant_access_link(application)
    else
      ""
    end
  end
end
