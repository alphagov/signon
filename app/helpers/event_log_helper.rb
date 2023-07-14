module EventLogHelper
  def formatted_date(log)
    log.created_at.to_fs(:govuk_date_short)
  end
end
