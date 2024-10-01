require "test_helper"

class OrganisationTest < ActiveSupport::TestCase
  def setup
    @organisation = create(:organisation)
  end

  test "organisation has ancestry" do
    assert_nothing_raised do
      Organisation.new.ancestors
    end
  end

  test "creating a new organisation using an existing slug should raise an exception" do
    assert_raises ActiveRecord::RecordInvalid do
      create(:organisation, slug: @organisation.slug)
    end
  end

  test "strips unwanted whitespace from name" do
    organisation = create(:organisation, name: "  An organisation ")

    assert_equal "An organisation", organisation.name
  end

  test "#not_closed" do
    create(:organisation, closed: true)

    assert_equal [@organisation], Organisation.not_closed.to_a
  end

  context "displaying name with abbreviation" do
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
