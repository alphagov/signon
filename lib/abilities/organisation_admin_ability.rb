class OrganisationAdminAbility
  include CanCan::Ability

  def initialize(user)
    return unless user.role? :organisation_admin

    can :read, Organisation, id: user.organisation.subtree.map(&:id)
    can [:read, :create, :update, :unlock, :invite!, :suspend, :unsuspend,
          :perform_admin_tasks, :resend_email_change, :cancel_email_change],
            User, organisation: { id: user.organisation.subtree.map(&:id) }

    cannot :manage, BatchInvitation
  end
end
