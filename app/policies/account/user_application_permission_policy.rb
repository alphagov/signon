class Account::UserApplicationPermissionPolicy < BasePolicy
  def show?
    Pundit.policy(current_user, user).edit?
  end

  def delete?
    return false unless show?
    return true if current_user.govuk_admin?

    current_user.has_access_to?(application) && application.signin_permission.delegatable?
  end
  alias_method :edit?, :delete?

  private

  delegate :user, :application, to: :record, allow_nil: true
end
