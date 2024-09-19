module OrganisationHelper
  def options_for_organisation_select(selected_id: nil)
    [{ text: Organisation::NONE, value: nil }] + policy_scope(Organisation).not_closed.map do |organisation|
      { text: organisation.name_with_abbreviation, value: organisation.id }.tap do |option|
        option[:selected] = true if option[:value] == selected_id
      end
    end
  end
end
