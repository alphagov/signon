class Account::ApplicationPolicy < BasePolicy
  def index?
    current_user.govuk_admin?
  end

  alias_method :show?, :index?
  alias_method :grant_signin_permission?, :index?
  alias_method :remove_signin_permission?, :index?
  alias_method :view_permissions?, :index?
end
