class UserPolicy < BasePolicy
  def index?
    current_user.superadmin? || current_user.admin? || current_user.organisation_admin?
  end

  def new? # invitations#new
    current_user.superadmin? || current_user.admin?
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
      !record.superadmin?
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

  def record_in_own_organisation?
    record.organisation && (record.organisation.id == current_user.organisation.id)
  end

  class Scope < ::BasePolicy::Scope
    def resolve
      if current_user.superadmin?
        scope.web_users
      elsif current_user.admin?
        scope.web_users.where(role: %w(admin organisation_admin normal))
      elsif current_user.organisation_admin?
        scope.web_users.where(role: %w(organisation_admin normal)).where(organisation_id: current_user.organisation_id)
      else
        scope.none
      end
    end
  end
end
