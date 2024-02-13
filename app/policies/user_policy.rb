class UserPolicy < BasePolicy
  def index?
    current_user.govuk_admin? || current_user.publishing_manager?
  end

  # invitations#new
  def new?
    current_user.govuk_admin?
  end
  alias_method :assign_organisation?, :new?

  # invitations#create
  alias_method :create?, :new?

  def edit?
    case current_user.role_name
    when Roles::Superadmin.name
      true
    when Roles::Admin.name
      can_manage?
    when Roles::SuperOrganisationAdmin.name
      can_manage? && (record_in_own_organisation? || record_in_child_organisation?)
    when Roles::OrganisationAdmin.name
      can_manage? && record_in_own_organisation?
    when Roles::Normal.name
      false
    else
      raise "Unknown role: #{current_user.role_name}"
    end
  end
  alias_method :update?, :edit?
  alias_method :unlock?, :edit?
  alias_method :suspension?, :edit?
  alias_method :resend_invitation?, :edit?
  alias_method :event_logs?, :edit?
  alias_method :mandate_2sv?, :edit?
  alias_method :require_2sv?, :edit?
  alias_method :reset_2sv?, :edit?
  alias_method :reset_two_step_verification?, :edit?
  alias_method :resend_email_change?, :edit?
  alias_method :cancel_email_change?, :edit?

  def assign_role?
    current_user.superadmin?
  end

  def exempt_from_two_step_verification?
    current_user.belongs_to_gds? &&
      current_user.govuk_admin? &&
      record.normal? &&
      record.web_user?
  end

private

  def can_manage?
    current_user.can_manage?(record)
  end

  class Scope < ::BasePolicy::Scope
    def resolve
      if current_user.superadmin?
        scope.web_users
      elsif current_user.admin?
        scope.web_users.where(role: current_user.manageable_roles.map(&:name))
      elsif current_user.super_organisation_admin?
        scope.web_users.where(role: current_user.manageable_roles.map(&:name)).where(organisation: current_user.organisation.subtree)
      elsif current_user.organisation_admin?
        scope.web_users.where(role: current_user.manageable_roles.map(&:name)).where(organisation: current_user.organisation)
      else
        scope.none
      end
    end
  end
end
