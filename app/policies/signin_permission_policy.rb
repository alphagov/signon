class SigninPermissionPolicy < BasePolicy
  def create?
    current_user.govuk_admin?
  end

  def delete?
    Pundit.policy(current_user, [:account, user_application_permission]).edit?
  end

  private

  delegate :user_application_permission, to: :record
end
