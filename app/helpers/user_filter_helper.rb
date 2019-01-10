module UserFilterHelper
  def orgs_that_user_is_allowed_to_see
    orgs = is_super_org_admin? ? current_user.organisation.subtree : Organisation
    orgs.order(:name).joins(:users).uniq.map { |org| [org.name_with_abbreviation.chomp, org.id] }
  end

  def filtered_user_roles
    current_user.manageable_roles
  end
end
