class Account::EmailsPolicy < BasePolicy
  def show?
    current_user.present?
  end
  alias_method :update?, :show?
  alias_method :resend_email_change?, :show?
  alias_method :cancel_email_change?, :show?
end
