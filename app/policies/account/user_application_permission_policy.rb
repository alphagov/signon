class Account::UserApplicationPermissionPolicy < BasePolicy
  def show?
    current_user.govuk_admin? || current_user.publishing_manager?
  end

  def delete?
    current_user.has_access_to?(application) &&
    (
      current_user.govuk_admin? ||
      current_user.publishing_manager? && application.signin_permission.delegatable?
    )
  end

  private

  delegate :user, :application, to: :record, allow_nil: true
end
