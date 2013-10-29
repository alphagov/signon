require 'test_helper'
require 'gds_api/test_helpers/organisations'

class OrganisationsFetcherTest < ActiveSupport::TestCase
  include GdsApi::TestHelpers::Organisations

  test "it creates new organisations when none exist" do
    organisation_slugs = %w(ministry-of-fun, tea-agency)
    organisations_api_has_organisations(organisation_slugs)
    assert_equal(0, Organisation.count)

    OrganisationsFetcher.new.call

    assert_equal(2, Organisation.count)
  end

  test "it updates an existing organisation when its data changes" do
    slug = 'ministry-of-fun'
    FactoryGirl.create(
      :organisation,
      name: 'Ministry Of Misery',
      slug: slug,
    )
    assert_equal(1, Organisation.count)

    organisations_api_has_organisations([slug])

    OrganisationsFetcher.new.call

    assert_equal(1, Organisation.count)
    assert_equal('Ministry Of Fun', Organisation.find_by_slug(slug).name)
  end

  test "it saves values which are not validated for presence, when they are present in the data" do
    slug = 'ministry-of-fun'
    organisations_api_has_organisations([slug])

    OrganisationsFetcher.new.call

    organisation = Organisation.find_by_slug(slug)
    assert_present(organisation.abbreviation)
  end

  test "it raises an error when it receives invalid data" do
    organisation_slugs = [""]
    organisations_api_has_organisations(organisation_slugs)

    assert_raises RuntimeError do
      OrganisationsFetcher.new.call
    end
  end

end
