class InactiveUsersSuspensionReminderMailingList
  DAYS_TO_SUSPENSION = [14, 7, 3, 1].freeze

  def initialize(suspension_threshold_period)
    @suspension_threshold_period = suspension_threshold_period
  end

  def generate
    suspension_threshold_exceeded = @suspension_threshold_period + 1.day

    suspension_reminder_mailing_list = DAYS_TO_SUSPENSION.index_with do |days_to_suspension|
      User.last_signed_in_on((suspension_threshold_exceeded - days_to_suspension.days).ago)
    end
    suspension_reminder_mailing_list[1] += User.not_recently_unsuspended.last_signed_in_before(suspension_threshold_exceeded.ago).to_a
    suspension_reminder_mailing_list
  end
end
