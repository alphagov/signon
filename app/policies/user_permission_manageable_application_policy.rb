# This policy controls which applications a given user is allowed to
# manage the permissions that other users have for it
class UserPermissionManageableApplicationPolicy
  attr_reader :current_user

  def initialize(current_user, _record = nil)
    @current_user = current_user
  end

  def scope
    PermissionGrantableApplicationPolicy::Scope.new(current_user).resolve
  end

  class Scope
    attr_reader :current_user

    def initialize(current_user, _record = nil)
      @current_user = current_user
    end

    def resolve
      if current_user.govuk_admin?
        applications
      elsif current_user.publishing_manager?
        applications.can_signin(current_user).with_signin_delegatable
      else
        applications.none
      end
    end

  private

    def applications
      Doorkeeper::Application.not_api_only.includes(:supported_permissions)
    end
  end
end
