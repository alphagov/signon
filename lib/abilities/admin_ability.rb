class AdminAbility
  include CanCan::Ability

  def initialize(user)
    return unless user.role? :admin

    can :read, Organisation
    can :manage, BatchInvitation
    can [:read, :create, :update, :unlock, :invite!, :suspend, :unsuspend,
          :resend_email_change, :cancel_email_change], User
  end
end
