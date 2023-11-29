class UserApplicationPermissionPolicy < BasePolicy
  def create?
    return false unless Pundit.policy(current_user, user).edit?

    return true if current_user.govuk_admin?

    current_user.publishing_manager? && current_user.has_access_to?(application) && application.signin_permission.delegatable?
  end
  alias_method :destroy?, :create?
  alias_method :delete?, :create?

  delegate :user, :application, to: :record
end
