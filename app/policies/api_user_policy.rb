class ApiUserPolicy < BasePolicy
  def new?
    current_user.superadmin?
  end
  alias_method :create?, :new?
  alias_method :index?, :new?
  alias_method :edit?, :new?
  alias_method :update?, :new?
  alias_method :revoke?, :new?
  alias_method :manage_tokens?, :new?
  alias_method :suspension?, :new?

  def resend_email_change? = false
  def cancel_email_change? = false
end
