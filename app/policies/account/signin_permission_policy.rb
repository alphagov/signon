class Account::SigninPermissionPolicy < BasePolicy
  def create?
    current_user.govuk_admin?
  end
end
