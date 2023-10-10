module RoleOrganisationsHelper
  def options_for_your_organisation_select(current_user)
    organisations = Pundit.policy_scope(current_user, Organisation).where(closed: false).order(:name)

    organisations.map do |organisation|
      { text: organisation.name_with_abbreviation,
        value: organisation.id,
        selected: current_user.organisation == organisation }
    end
  end
end
