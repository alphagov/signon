class Ability
  include CanCan::Ability

  def initialize(user)
    if user.role? :superadmin
      can [:read, :update], Doorkeeper::Application
      can [:read, :create, :update], SupportedPermission
      can :assign_role, User
    end

    if user.role? :admin
      can [:read], Organisation
      can [:read, :create], BatchInvitation
      can [:read, :create, :update, :unlock, :resend, :cancel_email_change, :resend_email_change], User
    end

  end
end
