module Abilities
  class Admin
    include CanCan::Ability

    def initialize(user)
      return unless user.role? :admin

      can :read, Organisation
      can [:read, :create], BatchInvitation
      can :delegate_all_permissions, ::Doorkeeper::Application
      can [:read, :create, :update, :unlock, :invite!, :suspend, :unsuspend,
            :perform_admin_tasks, :resend_email_change, :cancel_email_change], User, api_user: false
    end
  end
end
