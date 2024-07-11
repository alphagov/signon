class Users::ApplicationPolicy < BasePolicy
  attr_reader :user, :application

  def initialize(current_user, record)
    super

    @user = record[:user]
    @application = record[:application]
  end

  def grant_signin_permission?
    return false unless Pundit.policy(current_user, user).edit?
    return true if current_user.govuk_admin?

    current_user.publishing_manager? && current_user.has_access_to?(application) && application.signin_permission.delegatable?
  end
end
