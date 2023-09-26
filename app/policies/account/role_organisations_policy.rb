class Account::RoleOrganisationsPolicy < BasePolicy
  def show?
    current_user.present?
  end

  def update_organisation?
    current_user.govuk_admin?
  end
  alias_method :update_role?, :update_organisation?
end
