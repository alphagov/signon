class Account::ApplicationPolicy < BasePolicy
  def show?
    current_user.govuk_admin? || current_user.publishing_manager?
  end

  alias_method :index?, :show?
  alias_method :view_permissions?, :index?

  def grant_signin_permission?
    current_user.govuk_admin?
  end

  def remove_signin_permission?
    current_user.has_access_to?(record) &&
      (
        current_user.govuk_admin? ||
        current_user.publishing_manager? && record.signin_permission.delegatable?
      )
  end
  alias_method :edit_permissions?, :remove_signin_permission?
end
