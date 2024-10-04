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

  context "scopes" do
    setup do
      @closed_organisation_gas = create(:organisation, name: "Government Analogue Service", closed: true)
      @active_organisation_gds = create(:organisation, name: "Government Digital Service")
      @active_organisation_co = create(:organisation, name: "Cabinet Office")
      @closed_organisation_moj = create(:organisation, name: "Ministry of Jazztice", closed: true)
    end

    context ".all (default scope)" do
      should "return unclosed organisations before closed organisations, then alphabetically" do
        expected = [
          @active_organisation_co,
          @active_organisation_gds,
          @closed_organisation_gas,
          @closed_organisation_moj,
        ]

        assert_equal expected, Organisation.all
      end
    end

    context ".not_closed" do
      should "exclude closed organisations" do
        result = Organisation.not_closed.to_a

        assert_includes result, @active_organisation_co
        assert_includes result, @active_organisation_gds
        assert_not_includes result, @closed_organisation_gas
        assert_not_includes result, @closed_organisation_moj
      end
    end

    context ".closed" do
      should "only return closed organisations" do
        result = Organisation.closed.to_a

        assert_not_includes result, @active_organisation_co
        assert_not_includes result, @active_organisation_gds
        assert_includes result, @closed_organisation_gas
        assert_includes result, @closed_organisation_moj
      end
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
      setup do
        @organisation = build(:organisation, name: "An Organisation", closed: true)
      end

      should "append '(closed)'" do
        assert_equal "An Organisation (closed)", @organisation.name_with_abbreviation
      end

      context "but we don't want to indicate this" do
        should "not append '(closed)'" do
          assert_equal "An Organisation", @organisation.name_with_abbreviation(indicate_closed: false)
        end
      end
    end
  end
end
