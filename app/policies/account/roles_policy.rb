class Account::RolesPolicy < BasePolicy
  def show?
    current_user.present?
  end

  def update?
    current_user.superadmin?
  end
end
