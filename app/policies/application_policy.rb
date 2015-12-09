class ApplicationPolicy < BasePolicy
  def index?
    current_user.superadmin?
  end
  alias_method :edit?, :index?
  alias_method :update?, :index?
  alias_method :manage_supported_permissions?, :index?
  alias_method :users_with_access?, :index?
end
