class Account::RolesPolicy < BasePolicy
  def show?
    current_user.present?
  end

  def update_role?
    current_user.superadmin?
  end
end
