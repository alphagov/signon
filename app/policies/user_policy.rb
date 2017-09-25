class UserPolicy < BasePolicy
  def index?
    %w(superadmin admin super_organisation_admin organisation_admin).include? current_user.role
  end

  def new? # invitations#new
    %w(superadmin admin).include? current_user.role
  end
  alias_method :assign_organisations?, :new?

  def create? # invitations#create
    current_user.superadmin? || (current_user.admin? && !record.superadmin?)
  end

  def edit?
    case current_user.role
    when 'superadmin'
      true
    when 'admin'
      can_manage?
    when 'super_organisation_admin'
      allow_self_only || (can_manage? && (record_in_own_organisation? || record_in_child_organisation?))
    when 'organisation_admin'
      allow_self_only || (can_manage? && record_in_own_organisation?)
    else # 'normal'
      false
    end
  end
  alias_method :update?, :edit?
  alias_method :unlock?, :edit?
  alias_method :suspension?, :edit?
  alias_method :resend?, :edit?
  alias_method :event_logs?, :edit?

  def edit_email_or_passphrase?
    allow_self_only
  end
  alias_method :update_email?, :edit_email_or_passphrase?
  alias_method :update_passphrase?, :edit_email_or_passphrase?

  def cancel_email_change?
    allow_self_only || edit?
  end

  def resend_email_change?
    allow_self_only || edit?
  end

  def assign_role?
    current_user.superadmin?
  end

  def flag_2sv?
    current_user.superadmin?
  end

  def reset_2sv?
    current_user.superadmin?
  end
  alias_method :reset_two_step_verification?, :reset_2sv?

private

  def allow_self_only
    current_user.id == record.id
  end

  def can_manage?
    Roles.const_get(current_user.role.classify).can_manage?(record.role)
  end

  class Scope < ::BasePolicy::Scope
    def resolve
      if current_user.superadmin?
        scope.web_users
      elsif current_user.admin?
        scope.web_users.where(role: current_user.manageable_roles)
      elsif current_user.super_organisation_admin?
        scope.web_users.where(role: current_user.manageable_roles).where(organisation: current_user.organisation.subtree)
      elsif current_user.organisation_admin?
        scope.web_users.where(role: current_user.manageable_roles).where(organisation: current_user.organisation)
      else
        scope.none
      end
    end
  end
end
