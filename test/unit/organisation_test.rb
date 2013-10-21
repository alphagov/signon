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
end
