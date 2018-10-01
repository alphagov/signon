class UserParameterSanitiser
  def initialize(user_params:, current_user_role:, permitted_params_by_role: default_permitted_params_by_role)
    @user_params = user_params
    @current_user_role = current_user_role
    @permitted_params_by_role = permitted_params_by_role
  end

  def sanitise
    sanitised_params
  end

private

  attr_reader :user_params, :current_user_role, :permitted_params_by_role

  def sanitised_params
    ActionController::Parameters.new(user_params).permit(*permitted_params)
  end

  def permitted_params
    permitted_params_by_role.fetch(current_user_role, empty_whitelist)
  end

  def empty_whitelist
    []
  end

  def default_permitted_params_by_role
    {
      normal: Roles::Normal.permitted_user_params,
      organisation_admin: Roles::OrganisationAdmin.permitted_user_params,
      super_organisation_admin: Roles::SuperOrganisationAdmin.permitted_user_params,
      admin: Roles::Admin.permitted_user_params,
      superadmin: Roles::Superadmin.permitted_user_params,
    }
  end
end
