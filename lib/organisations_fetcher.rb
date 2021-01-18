require "gds_api/organisations"

# Whitehall is the canonical source for organisations, so Signon needs to keep
# its organisations up-to-date in order to provide accurate information on user
# membership of organisations.
class OrganisationsFetcher
  def call
    organisation_relationships = organisations.each_with_object({}) do |organisation_data, memo|
      update_or_create_organisation(organisation_data)
      memo[organisation_data["details"]["slug"]] = child_organisation_slugs(organisation_data)
    end

    update_ancestry(organisation_relationships)

    fix_parents_manually
  rescue ActiveRecord::RecordInvalid => e
    raise "Couldn't save organisation #{e.record.slug} because: #{e.record.errors.full_messages.join(',')}"
  end

  MANUAL_PARENT_FIXES = {
    "animal-and-plant-health-agency" => "department-for-environment-food-rural-affairs",
  }.freeze

private

  def organisations
    @organisations ||= GdsApi.organisations.organisations.with_subsequent_pages
  end

  def update_or_create_organisation(organisation_data)
    content_id = organisation_data["details"]["content_id"]
    slug = organisation_data["details"]["slug"]

    organisation = Organisation.find_by(content_id: content_id) ||
      Organisation.find_by(slug: slug) ||
      Organisation.new(content_id: content_id)

    update_data = {
      content_id: content_id,
      slug: slug,
      name: organisation_data["title"],
      organisation_type: organisation_data["format"],
      abbreviation: organisation_data["details"]["abbreviation"],
      closed: organisation_data["details"]["govuk_status"] == "closed",
    }

    organisation.update!(update_data)
  end

  def child_organisation_slugs(organisation_data)
    organisation_data["child_organisations"].map { |child_organisation| child_organisation["id"].split("/").last }
  end

  def update_ancestry(organisation_relationships)
    organisation_relationships.each do |organisation_slug, child_organisation_slugs|
      parent = Organisation.find_by!(slug: organisation_slug)
      Organisation.where(slug: child_organisation_slugs).find_each do |child_organisation|
        # TODO: This ignores that organisations can have multiple parents. Instead the
        # chosen parent will be the last parent in Whitehall, ordered alphabetically.
        child_organisation.update!(parent: parent)
      end
    end
  end

  def fix_parents_manually
    # Signon doesn't support multiple parents. Most of the time this is fine, but for
    # certain organisations this leads to a poor user experience and frequent support
    # tickets.
    MANUAL_PARENT_FIXES.each do |child_slug, parent_slug|
      child = Organisation.find_by(slug: child_slug)
      parent = Organisation.find_by(slug: parent_slug)
      next unless child && parent

      child.update!(parent: parent)
    end
  end
end
