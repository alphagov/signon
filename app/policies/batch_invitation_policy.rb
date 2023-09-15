class BatchInvitationPolicy < BasePolicy
  def new?
    return true if current_user.govuk_admin?

    false
  end
  alias_method :create?, :new?
  alias_method :show?, :new?
  alias_method :manage_permissions?, :new?
  alias_method :assign_organisation_from_csv?, :new?
end
