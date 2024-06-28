module ApplicationTableHelper
  include Pundit::Authorization

  def wrap_links_in_actions_markup(links)
    "<div class=\"govuk-table__actions\">#{links.join}</div>".html_safe
  end

  def account_applications_grant_access_link(application)
    if policy([:account, Doorkeeper::Application]).grant_signin_permission?
      grant_access_link(application)
    else
      ""
    end
  end

  def users_applications_grant_access_link(application, user)
    if policy(UserApplicationPermission.for(user, application)).create?
      grant_access_link(application, user)
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

  def users_applications_remove_access_link(application, user)
    if policy(UserApplicationPermission.for(user, application)).delete?
      remove_access_link(application, user)
    else
      ""
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

  def api_users_applications_permissions_link(application, user)
    update_permissions_link(application, user)
  end

private

  def grant_access_link(application, user = nil)
    path = if user
             user_application_signin_permission_path(user, application)
           else
             account_application_signin_permission_path(application)
           end

    button_to(
      path,
      class: "govuk-button govuk-!-margin-0",
      data: { module: "govuk-button" },
    ) { button_or_link_content("Grant access", "to", application.name) }
  end

  def remove_access_link(application, user = nil)
    path = if user
             delete_user_application_signin_permission_path(user, application)
           else
             delete_account_application_signin_permission_path(application)
           end

    link_to(
      path,
      class: "govuk-button govuk-button--warning govuk-!-margin-0",
      data: { module: "govuk-button" },
    ) { button_or_link_content("Remove access", "to", application.name) }
  end

  def view_permissions_link(application, user = nil)
    path = if user
             user_application_permissions_path(user, application)
           else
             account_application_permissions_path(application)
           end

    link_to(path, class: "govuk-link") { button_or_link_content("View permissions", "for", application.name) }
  end

  def update_permissions_link(application, user = nil)
    return "" if application.sorted_supported_permissions_grantable_from_ui(include_signin: false).none?

    path = if user.nil?
             edit_account_application_permissions_path(application)
           elsif user.api_user?
             edit_api_user_application_permissions_path(user, application)
           else
             edit_user_application_permissions_path(user, application)
           end

    link_to(path, class: "govuk-link") { button_or_link_content("Update permissions", "for", application.name) }
  end

  def button_or_link_content(visible_text, visually_hidden_join_word, application_name)
    safe_join([
      visible_text,
      content_tag(:span, " #{visually_hidden_join_word} #{application_name}", class: "govuk-visually-hidden"),
    ])
  end
end
