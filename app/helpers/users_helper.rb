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
end
