require 'test_helper'
require 'gds_api/test_helpers/organisations'

class OrganisationsFetcherTest < ActiveSupport::TestCase
  include GdsApi::TestHelpers::Organisations

  test "it creates new organisations when none exist" do
    organisation_slugs = %w(ministry-of-fun tea-agency)
    organisations_api_has_organisations(organisation_slugs)
    assert_equal(0, Organisation.count)

    OrganisationsFetcher.new.call

    assert_equal(2, Organisation.count)
  end

  test "it updates an existing organisation when its data changes" do
    slug = 'ministry-of-fun'
    create(
      :organisation,
      name: 'Ministry Of Misery',
      slug: slug,
      content_id: "a1b2c3",
    )
    assert_equal(1, Organisation.count)

    bodies = [
      organisation_details_for_slug(slug, "a1b2c3")
    ]
    organisations_api_has_organisations_with_bodies(bodies)

    OrganisationsFetcher.new.call

    assert_equal(1, Organisation.count)
    assert_equal('Ministry Of Fun', Organisation.find_by_slug(slug).name)
  end

  test "it updates an existing organisation when its slug changes" do
    slug = 'ministry-of-fun'
    create(
      :organisation,
      name: 'Ministry Of Misery',
      slug: "old-slug",
      content_id: "a1b2c3",
    )
    assert_equal(1, Organisation.count)

    bodies = [
      organisation_details_for_slug("new-slug", "a1b2c3")
    ]
    organisations_api_has_organisations_with_bodies(bodies)

    OrganisationsFetcher.new.call

    assert_equal(1, Organisation.count)
    assert_equal("new-slug", Organisation.first.slug)
  end

  test "it updates the child organisation with information about it's parent" do
    slug = 'ministry-of-fun'
    fun = create(:organisation, name: 'Ministry of Fun', slug: slug, content_id: "g0h9j8")
    child_slug = 'ministry-of-fun-child-1' # hard-coded in gds_api_adapters
    movies = create(:organisation, name: 'Ministry of Movies', slug: child_slug, content_id: "y2u3i4")

    bodies = [
      organisation_details_for_slug(slug, "g0h9j8")
    ]
    organisations_api_has_organisations_with_bodies(bodies)

    OrganisationsFetcher.new.call

    assert_equal [movies], fun.children
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
