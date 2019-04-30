class SplunkLogStreamingJob < ActiveJob::Base
  queue_as :logstream

  def perform(id, options = {})
    EventLog.find(id).send_to_splunk(options)
  end
end
