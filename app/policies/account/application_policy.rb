class Account::ApplicationPolicy < BasePolicy
  def index?
    current_user.govuk_admin?
  end

  alias_method :show?, :index?
end
