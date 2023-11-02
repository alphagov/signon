module AccountHelper
  def two_step_verification_page_title
    if current_user.has_2sv?
      "Change your 2-step verification phone"
    else
      "Set up 2-step verification"
    end
  end

  def role_page_title
    if policy(%i[account roles]).update_role?
      "Change your role"
    else
      "View your role"
    end
  end

  def organisation_page_title
    if policy(%i[account organisations]).update_organisation?
      "Change your organisation"
    else
      "View your organisation"
    end
  end

  def current_user_organisation_name
    current_user.organisation&.name_with_abbreviation || "No organisation"
  end
end
