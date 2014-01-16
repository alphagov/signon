module Abilities
  class Superadmin
    include CanCan::Ability

    def initialize(user)
      return unless user.role? :superadmin

      can [:read], Organisation
      can [:read, :create], BatchInvitation
      can [:read, :update, :delegate_all_permissions], Doorkeeper::Application
      can [:read, :create, :update], SupportedPermission
      can [:read, :create, :update, :assign_role, :unlock,
            :invite!, :perform_admin_tasks, :suspend, :unsuspend,
            :resend_email_change, :cancel_email_change], User, api_user: false
    end
  end
end
