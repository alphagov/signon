class Account::EmailPasswordsPolicy < BasePolicy
  def show?
    current_user.present?
  end
  alias_method :update_email?, :show?
  alias_method :update_password?, :show?
  alias_method :resend_email_change?, :show?
end
