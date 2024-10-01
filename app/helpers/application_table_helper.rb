module ApplicationTableHelper
  include Pundit::Authorization

  def account_applications_grant_access_link(application)
    if policy([:account, Doorkeeper::Application]).grant_signin_permission?
      grant_access_link(application)
    else
      ""
    end
  end

  def users_applications_grant_access_link(application, user)
    if Users::ApplicationPolicy.new(current_user, { application:, user: }).grant_signin_permission?
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
    if Users::ApplicationPolicy.new(current_user, { application:, user: }).remove_signin_permission?
      remove_access_link(application, user)
    else
      ""
    end
  end

  def account_applications_permissions_links(application)
    links = []

    links << view_permissions_link(application) if policy([:account, application]).view_permissions?
    links << update_permissions_link(application) if policy([:account, application]).edit_permissions?

    safe_join(links)
  end

  def users_applications_permissions_links(application, user)
    links = []
    policy = Users::ApplicationPolicy.new(current_user, { application:, user: })

    links << view_permissions_link(application, user) if policy.view_permissions?
    links << update_permissions_link(application, user) if policy.edit_permissions?

    safe_join(links)
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
    ) { button_or_link_content("Grant", "access to", application.name) }
  end

  def remove_access_link(application, user = nil)
    path = if user
             delete_user_application_signin_permission_path(user, application)
           else
             delete_account_application_signin_permission_path(application)
           end

    link_to(
      path,
      class: "govuk-button govuk-button--warning govuk-!-margin-0 applications-table__remove_access_link",
      data: { module: "govuk-button" },
    ) { button_or_link_content("Remove", "access to", application.name) }
  end

  def view_permissions_link(application, user = nil)
    path = if user
             user_application_permissions_path(user, application)
           else
             account_application_permissions_path(application)
           end

    link_to(path, class: "govuk-link") { button_or_link_content("View", "permissions for", application.name) }
  end

  def update_permissions_link(application, user = nil)
    if current_user.govuk_admin?
      return "" unless application.has_non_signin_permissions_grantable_from_ui?
    elsif current_user.publishing_manager?
      return "" unless application.has_delegatable_non_signin_permissions_grantable_from_ui?
    end

    path = if user.nil?
             edit_account_application_permissions_path(application)
           elsif user.api_user?
             edit_api_user_application_permissions_path(user, application)
           else
             edit_user_application_permissions_path(user, application)
           end

    link_to(path, class: "govuk-link") { button_or_link_content("Update", "permissions for", application.name) }
  end

  def button_or_link_content(visible_text, visually_hidden_join_word, application_name)
    safe_join([
      visible_text,
      content_tag(:span, " #{visually_hidden_join_word} #{application_name}", class: "govuk-visually-hidden"),
    ])
  end
end
