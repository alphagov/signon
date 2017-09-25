class BasePolicy
  attr_reader :current_user, :record

  def initialize(current_user, record)
    @current_user = current_user
    @record = record
  end

  def scope
    Pundit.policy_scope!(current_user, record.class)
  end

  protected

  def record_in_own_organisation?
    record.organisation && (record.organisation_id == current_user.organisation_id)
  end

  def record_in_child_organisation?
    current_user.organisation.subtree.include?(record.organisation)
  end

  class Scope
    attr_reader :current_user, :scope

    def initialize(current_user, scope)
      @current_user = current_user
      @scope = scope
    end

    def resolve
      scope
    end
  end
end
