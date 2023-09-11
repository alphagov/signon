class AccountPagePolicy < BasePolicy
  def show?
    current_user.present?
  end
end
