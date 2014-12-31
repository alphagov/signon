class BatchInvitationPolicy < BasePolicy

  def new?
    current_user.superadmin? || current_user.admin? || current_user.organisation_admin?
  end
  alias_method :create?, :new?
  alias_method :show?, :new?

end
