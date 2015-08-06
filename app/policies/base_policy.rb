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

  def belong_to_same_organisation_subtree?(current_user, record)
    current_user.organisation.subtree.pluck(:id).include?(record.organisation_id.to_i)
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
