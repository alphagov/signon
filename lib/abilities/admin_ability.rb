class AdminAbility
  include CanCan::Ability

  def initialize(user)
    return unless user.role? :admin

    can [:read], Organisation
    can [:read, :create], BatchInvitation
    can [:read, :create, :update, :unlock, :invite!, :resend_email_change, :cancel_email_change], User
  end
end
