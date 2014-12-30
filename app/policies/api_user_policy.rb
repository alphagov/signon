class ApiUserPolicy < BasePolicy

  def new?
    current_user.superadmin?
  end

  def create?
    new?
  end

  def index?
    current_user.superadmin?
  end

  def edit?
    current_user.superadmin?
  end

  def update?
    edit?
  end

  def revoke?
    edit?
  end

end
