class Account::OrganisationsPolicy < BasePolicy
  def show?
    current_user.present?
  end

  def update_organisation?
    current_user.govuk_admin?
  end
end
