class UserApplicationPermissionPolicy < BasePolicy
  def index?
    Pundit.policy(current_user, user).edit?
  end

  def remove_signin_permission?
    user.has_access_to?(application) &&
      (
        current_user.govuk_admin? ||
        current_user.publishing_manager? && application.signin_permission.delegatable?
      )
  end

  def edit_permissions?
    remove_signin_permission?
  end

  def view_permissions?
    Pundit.policy(current_user, user).edit? &&
      user.has_access_to?(application)
  end

  def delete?
    edit_permissions?
  end

  def destroy?
    delete?
  end

  def show?
    view_permissions?
  end

  def edit?
    edit_permissions?
  end

  def update?
    edit_permissions?
  end

  private

  def user
    record.user
  end

  def application
    record.application
  end
end
