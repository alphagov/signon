require "test_helper"

class OrganisationHelperTest < ActionView::TestCase
  setup do
    @gds = create(:organisation, name: "Government Digital Service", abbreviation: "GDS")
    @gas = create(:organisation, name: "Government Analogue Service", abbreviation: "GAS")
    @unabbreviated = create(:organisation, name: "unAbbreviaTed")

    stubs(:policy_scope).with(Organisation).returns(Organisation.all)
  end

  should "return a select option for each organisation sorted alphabetically, preceded by a 'None' option" do
    expected = [
      { text: "None", value: nil },
      { text: "Government Analogue Service - GAS", value: @gas.id },
      { text: "Government Digital Service - GDS", value: @gds.id },
      { text: "unAbbreviaTed", value: @unabbreviated.id },
    ]

    assert_equal expected, options_for_organisation_select
  end

  context "when a closed organisation exists" do
    setup do
      @closed = create(:organisation, name: "Prehistoric Government Service", closed: true)
    end

    should "exclude the closed organisation" do
      unexpected_closed_option = { text: "Prehistoric Government Service", value: @closed.id }

      assert_not_includes options_for_organisation_select, unexpected_closed_option
    end
  end

  context "when a selection is provided" do
    should "mark the selection as selected" do
      selected_option = { text: "Government Analogue Service - GAS", value: @gas.id, selected: true }

      assert_includes options_for_organisation_select(selected_id: @gas.id), selected_option
    end
  end

  context "when there are no organisations the current user can select" do
    setup do
      stubs(:policy_scope).with(Organisation).returns(Organisation.where("false"))
    end

    should "return only a 'None' option" do
      expected = [{ text: "None", value: nil }]

      assert_equal expected, options_for_organisation_select
    end
  end
end
