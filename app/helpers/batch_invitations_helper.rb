module BatchInvitationsHelper
  def batch_invite_status_link(batch_invitation, &block)
    if !batch_invitation.has_permissions?
      link_to(new_batch_invitation_permissions_path(batch_invitation), alt: "Edit this batch's permissions", &block)
    else
      link_to(batch_invitation_path(batch_invitation), alt: "View this batch", &block)
    end
  end

  def batch_invite_status_message(batch_invitation)
    if batch_invitation.in_progress?
      "In progress. " \
        "#{batch_invitation.batch_invitation_users.processed.count} of " \
        "#{batch_invitation.batch_invitation_users.count} " \
        "users processed."
    elsif batch_invitation.all_successful?
      "#{batch_invitation.batch_invitation_users.count} users processed."
    elsif !batch_invitation.has_permissions?
      "Batch invitation doesn't have any permissions yet."
    else
      "#{pluralize(batch_invitation.batch_invitation_users.failed.count, 'error')} out of " \
        "#{batch_invitation.batch_invitation_users.count} " \
        "users processed."
    end
  end

  def batch_invite_organisation_for_user(batch_invitation_user)
    Organisation.find(batch_invitation_user.organisation_id).name
  rescue BatchInvitationUser::InvalidOrganisationSlug, ActiveRecord::RecordNotFound
    ""
  end
end
