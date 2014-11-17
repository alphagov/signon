class OrganisationSlugUpdater
  def initialize(old_slug, new_slug, logger = nil)
    @old_slug = old_slug.sub(%r{^/}, '')
    @new_slug = new_slug.sub(%r{^/}, '')
    @logger   = logger || Logger.new(nil)
  end

  def call
    if organisation
      update_organisation_slug
    else
      logger.error("No organisation found for slug: #{old_slug}")
      false
    end
  end

private
  attr_reader(
    :old_slug,
    :new_slug,
    :logger,
  )

  def organisation
    @organisation ||= Organisation.where(slug: old_slug).first
  end

  def update_organisation_slug
    updated_result = organisation.update_attribute(:slug, new_slug)
    logger.info("Updated organisation with slug '#{old_slug}' to use slug '#{new_slug}'")
    updated_result
  end
end
