require "test_helper"

class OrganisationTest < ActiveSupport::TestCase
  should "have ancestry" do
    assert_nothing_raised do
      Organisation.new.ancestors
    end
  end

  should "raise an exception when creating a new organisation using an existing slug" do
    existing_organisation = create(:organisation)

    assert_raises ActiveRecord::RecordInvalid do
      create(:organisation, slug: existing_organisation.slug)
    end
  end

  should "strip unwanted whitespace from name" do
    organisation = create(:organisation, name: "  An organisation ")

    assert_equal "An organisation", organisation.name
  end

  context ".not_closed" do
    should "exclude closed organisations" do
      active_organisation = create(:organisation)
      closed_organisation = create(:organisation, closed: true)

      result = Organisation.not_closed.to_a

      assert_includes result, active_organisation
      assert_not_includes result, closed_organisation
    end
  end

  context "#name_with_abbreviation" do
    should "use abbreviation when it is not the same as name" do
      organisation = build(:organisation, name: "An Organisation", abbreviation: "ABBR")
      assert_equal "An Organisation - ABBR", organisation.name_with_abbreviation
    end

    should "not use abbreviation when it is not present" do
      organisation = build(:organisation, name: "An Organisation", abbreviation: "   ")
      assert_equal organisation.name, organisation.name_with_abbreviation
    end

    should "not use abbreviation when it is present but the same as name" do
      organisation = build(:organisation, name: "An Organisation", abbreviation: "An Organisation")
      assert_equal organisation.name, organisation.name_with_abbreviation
    end

    context "when the organisation is closed" do
      should "append (closed)" do
        organisation = build(:organisation, name: "An Organisation", closed: true)
        assert_equal "An Organisation (closed)", organisation.name_with_abbreviation
      end
    end
  end
end
