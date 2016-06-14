class BatchInvitationPolicy < BasePolicy
  def new?
    return true if current_user.superadmin? || current_user.admin?
    return belong_to_same_organisation_subtree?(current_user, record) if current_user.organisation_admin?

    false
  end
  alias_method :create?, :new?
  alias_method :show?, :new?
end
