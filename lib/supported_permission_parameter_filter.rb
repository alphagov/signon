class SupportedPermissionParameterFilter
  attr_reader :current_user, :user, :param_set
  def initialize(current_user, user, param_set)
    @current_user = current_user
    @user = user
    @param_set = param_set
  end

  def filtered_supported_permission_ids
    # any permissions not in "attempting_to_add" should be removed if we're
    # allowed to manipulate them
    allowed_to_be_removed = authorised_supported_permission_ids - attempting_to_set_supported_permission_ids
    # any permissions in "attempting_to_add" should be added if they're in the
    # set we're allowed to manipulate
    allowed_to_be_added = attempting_to_set_supported_permission_ids & authorised_supported_permission_ids

    (existing_supported_permission_ids - allowed_to_be_removed) | allowed_to_be_added
  end

private

  def authorised_supported_permission_ids
    @authorised_supported_permission_ids ||=
      Pundit
        .policy_scope(current_user, SupportedPermission)
        .pluck(:id)
        .map(&:to_s)
  end

  def existing_supported_permission_ids
    @existing_supported_permission_ids ||= user.supported_permission_ids.map(&:to_s)
  end

  def attempting_to_set_supported_permission_ids
    @attempting_to_set_supported_permission_ids ||= param_set.fetch(:supported_permission_ids, []).map(&:to_s)
  end
end
