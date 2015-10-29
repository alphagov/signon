module AnalyticsHelper
  def track_analytics_data(type, message)
    {
      'module' => 'auto-track-event',
      'track-action' => "alert-#{type}",
      'track-label' => flash_text_without_email_addresses(message)
    }
  end
end
