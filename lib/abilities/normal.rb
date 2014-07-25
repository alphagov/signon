module Abilities
  class Normal
    include CanCan::Ability

    def initialize(user)
      can [:read, :update], User, { id: user.id, api_user: false }
      cannot [:index, :invite!], User

      cannot :manage, [ApiUser, Doorkeeper::AccessToken]
    end
  end
end
