# This policy controls which applications a given user is allowed to
# manage the permissions that other users have for it
class UserPermissionManageableApplicationPolicy
  attr_reader :current_user

  def initialize(current_user, _ = nil)
    @current_user = current_user
  end

  def scope
    PermissionGrantableApplicationPolicy::Scope.new(current_user).resolve
  end

  class Scope
    attr_reader :current_user

    def initialize(current_user, _ = nil)
      @current_user = current_user
    end

    def resolve
      if current_user.superadmin?
        applications
      elsif current_user.admin?
        applications
      elsif current_user.super_organisation_admin?
        applications.can_signin(current_user).with_signin_delegatable
      elsif current_user.organisation_admin?
        applications.can_signin(current_user).with_signin_delegatable
      else
        applications.none
      end
    end

  private

    def applications
      ::Doorkeeper::Application.includes(:supported_permissions)
    end
  end
end
