class ApiUserPolicy < BasePolicy
  def new?
    current_user.superadmin?
  end
  alias_method :create?, :new?
  alias_method :index?, :new?
  alias_method :edit?, :new?
  alias_method :update?, :new?
  alias_method :revoke?, :new?
end
