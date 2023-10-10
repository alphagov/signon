require "test_helper"

class RoleOrganisationsHelperTest < ActionView::TestCase
  context "#options_for_your_organisation_select" do
    setup do
      @user_organisation = create(:organisation, name: "User Organisation", abbreviation: "UO")
      @other_organisation = create(:organisation, name: "Other Organisation")
      @user = create(:admin_user, organisation: @user_organisation)
    end

    should "return options suitable for select component with users organisation selected" do
      options = options_for_your_organisation_select(@user)

      expected_options = [
        {
          text: "Other Organisation",
          value: @other_organisation.id,
          selected: false,
        },
        {
          text: "User Organisation – UO",
          value: @user_organisation.id,
          selected: true,
        },
      ]

      assert_equal expected_options, options
    end

    should "sort by organisation name alphabetically" do
      options = options_for_your_organisation_select(@user)

      assert_equal ["Other Organisation", "User Organisation – UO"], (options.map { |o| o[:text] })
    end
  end
end
