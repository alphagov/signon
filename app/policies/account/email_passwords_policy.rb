class Account::EmailPasswordsPolicy < BasePolicy
  def show?
    current_user.present?
  end
end
