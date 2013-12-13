module Abilities
  class Normal
    include CanCan::Ability

    def initialize(user)
      can [:read, :update], User, id: user.id
      cannot [:index, :invite!], User
    end
  end
end
