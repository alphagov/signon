module OrganisationHelper
  def options_for_organisation_select(selected_id: nil, include_closed: false)
    organisations_scope = policy_scope(Organisation).then do |scope|
      include_closed ? scope : scope.not_closed
    end

    [{ text: Organisation::NONE, value: nil }] + organisations_scope.map do |organisation|
      { text: organisation.name_with_abbreviation, value: organisation.id }.tap do |option|
        option[:selected] = true if option[:value] == selected_id
      end
    end
  end
end
