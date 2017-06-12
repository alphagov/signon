class BatchInvitationPolicy < BasePolicy
  def new?
    return true if current_user.superadmin? || current_user.admin?

    false
  end
  alias_method :create?, :new?
  alias_method :show?, :new?
end
