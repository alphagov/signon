module EventLogHelper
  def formatted_date(log)
    log.created_at.to_fs(:govuk_date_short)
  end

  def formatted_event(log)
    log.event
  end

  def formatted_application(log)
    if log.application
      "for <strong>#{log.application.name}</strong>".html_safe
    end
  end

  def formatted_initiator(log)
    if log.initiator
      "by <strong>#{link_to log.initiator.name, users_path(filter: log.initiator.email), title: log.initiator.email}</strong>".html_safe
    end
  end

  def formatted_trailing_message(log)
    log.trailing_message
  end

  def formatted_ip_address(log)
    if log.ip_address
      log.ip_address_string
    end
  end

  def formatted_user_agent(log)
    if log.user_agent_id
      browser = Browser.new(log.user_agent_as_string)
      "#{browser.name} #{browser.version}"
    end
  end
end
