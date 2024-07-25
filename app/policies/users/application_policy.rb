class Users::ApplicationPolicy < BasePolicy
  attr_reader :user, :application

  def initialize(current_user, record)
    super

    @user = record[:user]
    @application = record[:application]
  end

  def grant_signin_permission?
    return false unless Pundit.policy(current_user, user).edit?
    return true if current_user.govuk_admin?

    current_user.publishing_manager? && current_user.has_access_to?(application) && application.signin_permission.delegatable?
  end

  alias_method :remove_signin_permission?, :grant_signin_permission?

  def view_permissions?
    Pundit.policy(current_user, user).edit?
  end

  def edit_permissions?
    return false unless Pundit.policy(current_user, user).edit?
    return true if current_user.govuk_admin?

    current_user.publishing_manager? && current_user.has_access_to?(application) && application.has_delegatable_non_signin_permissions?
  end
end
