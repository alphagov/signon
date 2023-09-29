class Account::ManagePermissionsPolicy < BasePolicy
  def show?
    !current_user.normal?
  end
  alias_method :update?, :show?
end
