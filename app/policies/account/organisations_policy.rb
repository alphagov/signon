class Account::OrganisationsPolicy < BasePolicy
  def edit?
    current_user.present?
  end

  def update?
    current_user.govuk_admin?
  end
end
