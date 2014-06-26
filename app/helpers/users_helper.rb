module UsersHelper
  def organisation_options(form_builder)
    accessible_organisations = Organisation.accessible_by(current_ability)
    options_from_collection_for_select(accessible_organisations, :id,
      :name_with_abbreviation, selected: form_builder.object.organisation_id)
  end

  def organisation_select_options
    { include_blank: current_user.role == 'organisation_admin' ? false : 'None' }
  end

  def user_email_tokens(user = current_user)
    [ user.email ] + DeviseZxcvbn::EmailTokeniser.split(user.email)
  end

  def minimum_password_length
    User.password_length.min
  end

  def current_path_with_role_filter(role_name)
    query_parameters = (request.query_parameters || {})
    role_name.nil? ? query_parameters.delete(:role) : query_parameters.merge!(role: role_name)
    request.path_info + '?' + query_parameters.map { |k,v| "#{k}=#{v}" }.join('&')
  end

end
