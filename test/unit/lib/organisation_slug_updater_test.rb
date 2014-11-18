require 'test_helper'

class OrganisationSlugUpdaterTest < ActionView::TestCase

  def setup
    @new_slug = "my-new-slug"
    @organisation = FactoryGirl.create(:organisation)
  end

  def test_returns_true_if_updated
    assert(OrganisationSlugUpdater.new(@organisation.slug, @new_slug).call)
  end

  def test_organisation_slug_updated
    OrganisationSlugUpdater.new(@organisation.slug, @new_slug).call
    assert_equal(@new_slug, @organisation.reload.slug)
  end

  def test_organisation_slug_doesnt_contain_leading_slash
    OrganisationSlugUpdater.new(@organisation.slug, "/new-slug-with-leading-slash").call
    assert_equal("new-slug-with-leading-slash", @organisation.reload.slug)
  end

  def test_returns_false_if_there_is_no_organisation
    assert_equal(false, OrganisationSlugUpdater.new('anything', @new_slug).call)
  end
end
