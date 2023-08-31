class BulkGrantPermissionSetPolicy < BasePolicy
  def new?
    return true if current_user.govuk_admin?

    false
  end
  alias_method :create?, :new?
  alias_method :show?, :new?
end
