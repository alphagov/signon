require 'test_helper'

class OrganisationTest < ActiveSupport::TestCase

  def setup
    @organisation = FactoryGirl.create(:organisation)
  end

  test "creating a new organisation using an existing slug should raise an exception" do
    assert_raises ActiveRecord::RecordInvalid do
      FactoryGirl.create(:organisation, slug: @organisation.slug)
    end
  end

  context "displaying name with abbreviation" do
    should "use abbreviation when it is not the same as name" do
      organisation = FactoryGirl.build(:organisation, name: 'An Organisation', abbreviation: "ABBR")
      assert_equal "An Organisation | ABBR", organisation.name_with_abbreviation
    end

    should "not use abbreviation when it is not present" do
      organisation = FactoryGirl.build(:organisation, name: 'An Organisation', abbreviation: "   ")
      assert_equal organisation.name, organisation.name_with_abbreviation
    end

    should "not use abbreviation when it is present but the same as name" do
      organisation = FactoryGirl.build(:organisation, name: 'An Organisation', abbreviation: 'An Organisation')
      assert_equal organisation.name, organisation.name_with_abbreviation
    end
  end
end
