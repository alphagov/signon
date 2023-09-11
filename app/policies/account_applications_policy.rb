class AccountApplicationsPolicy < BasePolicy
  def index?
    current_user.govuk_admin?
  end
end
