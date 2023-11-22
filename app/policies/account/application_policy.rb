class Account::ApplicationPolicy < BasePolicy
  def index?
    current_user.govuk_admin? || current_user.publishing_manager?
  end

  alias_method :show?, :index?
end
