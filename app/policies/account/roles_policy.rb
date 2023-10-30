class Account::RolesPolicy < BasePolicy
  def edit?
    current_user.present?
  end

  def update?
    current_user.superadmin?
  end
end
