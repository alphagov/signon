Doorkeeper::OAuth::PreAuthorization.class_eval do
  alias_method :old_validate_scopes, :validate_scopes

  def scope
    @scope.presence || build_scopes
  end

  def validate_scopes
    return true if scope.blank?

    old_validate_scopes
  end

  def validate_params
    response_type.blank? ? :response_type : true
  end
end
