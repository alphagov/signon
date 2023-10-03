class Account::RoleOrganisationsPolicy < BasePolicy
  def show?
    current_user.present?
  end

  def update_organisation?
    current_user.govuk_admin?
  end

  def update_role?
    current_user.superadmin?
  end
end
