class Account::PasswordsPolicy < BasePolicy
  def edit?
    current_user.present?
  end
  alias_method :update?, :edit?
end
