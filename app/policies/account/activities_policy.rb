class Account::ActivitiesPolicy < BasePolicy
  def show?
    current_user.present?
  end
end
