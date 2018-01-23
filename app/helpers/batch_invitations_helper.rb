module BatchInvitationsHelper
  def batch_invite_status_message(batch_invitation)
    if batch_invitation.in_progress?
      "In progress. " +
        "#{batch_invitation.batch_invitation_users.processed.count} of " +
        "#{batch_invitation.batch_invitation_users.count} " +
        "users processed."
    elsif batch_invitation.all_successful?
      "#{batch_invitation.batch_invitation_users.count} users processed."
    else
      "#{pluralize(batch_invitation.batch_invitation_users.failed.count, 'error')} out of " +
        "#{batch_invitation.batch_invitation_users.count} " +
        "users processed."
    end
  end

  def batch_invite_organisation_for_user(batch_invitation_user)
    Organisation.find(batch_invitation_user.organisation_id).name
  rescue BatchInvitationUser::InvalidOrganisationSlug, ActiveRecord::RecordNotFound
    ''
  end
end
