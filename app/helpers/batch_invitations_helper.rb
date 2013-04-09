module BatchInvitationsHelper
  def status_message(batch_invitation)
    first_part = if batch_invitation.in_progress?
      "In progress."
    elsif batch_invitation.outcome == "success"
      "Success!"
    elsif batch_invitation.outcome == "failure"
      "Failure!"
    end

    "#{first_part} #{batch_invitation.batch_invitation_users.processed.count} of #{batch_invitation.batch_invitation_users.count} users processed."
  end
end
