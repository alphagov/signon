class AdminAbility
  include CanCan::Ability

  def initialize(user)
    return unless user.role? :admin

    can [:read], Organisation
    can [:read, :create], BatchInvitation
    can [:read, :create, :update, :unlock, :cancel_email_change, :resend_email_change], User
  end
end
