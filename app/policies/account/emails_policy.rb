class Account::EmailsPolicy < BasePolicy
  def edit?
    current_user.present?
  end
  alias_method :update?, :edit?
  alias_method :resend_email_change?, :edit?
  alias_method :cancel_email_change?, :edit?
end
