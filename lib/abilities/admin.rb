module Abilities
  class Admin
    include CanCan::Ability

    def initialize(user)
      return unless user.role? :admin

      can :read, Organisation
      can [:read, :create], BatchInvitation
      cannot :delegate_all_permissions, ::Doorkeeper::Application
      can [:read, :create, :update, :unlock, :invite!, :suspend, :unsuspend,
            :perform_admin_tasks, :resend_email_change, :cancel_email_change, :assign_role],
          User,
          { api_user: false,
            role: Roles::Admin.manageable_roles }

      can [:read], EventLog

      cannot :manage, [ApiUser, Doorkeeper::AccessToken]
    end
  end
end
