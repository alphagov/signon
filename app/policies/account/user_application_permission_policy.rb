class Account::UserApplicationPermissionPolicy < BasePolicy
  def show?
    current_user.govuk_admin? || current_user.publishing_manager?
  end
end
