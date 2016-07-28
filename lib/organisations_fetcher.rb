require 'gds_api/organisations'

# Whitehall is the canonical source for organisations, so Signon needs to keep
# its organisations up-to-date in order to provide accurate information on user
# membership of organisations.
class OrganisationsFetcher
  def call
    organisation_relationships = {}
    organisations.each do |organisation_data|
      update_or_create_organisation(organisation_data)
      organisation_relationships[organisation_data.details.slug] = child_organisation_slugs(organisation_data)
    end
    # Now that any new organisations have been created and any slug changes
    # have been applied, we can safely tie together organisations
    update_ancestry(organisation_relationships)
  rescue ActiveRecord::RecordInvalid => invalid
    raise "Couldn't save organisation #{invalid.record.slug} because: #{invalid.record.errors.full_messages.join(',')}"
  end

private

  def organisations
    base_uri = Plek.current.find('whitehall-admin')
    GdsApi::Organisations.new(base_uri).organisations.with_subsequent_pages
  end

  def update_or_create_organisation(organisation_data)
    content_id = organisation_data.details.content_id
    slug = organisation_data.details.slug

    organisation = Organisation.find_by(content_id: content_id) ||
      Organisation.find_by(slug: slug) ||
      Organisation.new(content_id: content_id)

    update_data = {
      content_id: content_id,
      slug: slug,
      name: organisation_data.title,
      organisation_type: organisation_data.format,
      abbreviation: organisation_data.details.abbreviation,
      closed: organisation_data.details.govuk_status == 'closed',
    }
    organisation.update_attributes!(update_data)
  end

  def child_organisation_slugs(organisation_data)
    organisation_data.child_organisations.map(&:id).collect { |child_organisation_id| child_organisation_id.split('/').last }
  end

  def update_ancestry(organisation_relationships)
    organisation_relationships.each do |organisation_slug, child_organisation_slugs|
      parent = Organisation.find_by_slug(organisation_slug)
      Organisation.where(slug: child_organisation_slugs).map do |child_organisation|
        # TODO this ignores that organisations can have multiple parents. I think organisations will
        # end up with the parent that appears last in the API response(s).
        #
        # Transition app implements this correctly.
        child_organisation.update_attributes!(parent: parent)
      end
    end
  end
end
