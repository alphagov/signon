class Account::PasswordsPolicy < BasePolicy
  def show?
    current_user.present?
  end
  alias_method :update?, :show?
end
