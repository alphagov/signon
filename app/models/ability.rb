class Ability
  include CanCan::Ability

  def initialize(user)
    if user.role? :superadmin
      can [:read, :update], Doorkeeper::Application
      can [:read, :create, :update], SupportedPermission
      can :assign_role, User
    end
  end
end
