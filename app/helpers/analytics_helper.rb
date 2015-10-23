module AnalyticsHelper
  def analytics_attributes_alert(type, message)
    safe_message = flash_text_without_email_addresses(message)

    "data-module=\"auto-track-event\"\
     data-track-action=\"alert-#{type}\"\
     data-track-label=\"#{safe_message}\"".html_safe
  end

  def analytics_attributes_alert_danger(message)
    analytics_attributes_alert('danger', message)
  end
end
