class AuthorisationPolicy < BasePolicy
  def new?
    current_user.superadmin?
  end
  alias_method :create?, :new?
  alias_method :edit?, :new?
  alias_method :revoke?, :new?
end
