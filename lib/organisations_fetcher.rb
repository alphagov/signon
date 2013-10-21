require 'gds_api/organisations'

class OrganisationsFetcher

  def call
    organisations.each { |org_data| update_or_create_organisation(org_data) }
  end

private

  def organisations
    base_uri = Plek.current.find('whitehall-admin')
    GdsApi::Organisations.new(base_uri).organisations.with_subsequent_pages
  end

  def update_or_create_organisation(org_data)
    organisation = Organisation.find_or_initialize_by_slug(org_data.details.slug)
    update_data = {
      name: org_data.title,
      organisation_type: org_data.format,
      abbreviation: org_data.details.abbreviation,
      closed_at: org_data.details.closed_at,
    }
    organisation.update_attributes!(update_data)
  rescue ActiveRecord::RecordInvalid => e
    raise "Couldn't save organisation #{org_data.details.slug} because: #{e.message}"
  end
end
