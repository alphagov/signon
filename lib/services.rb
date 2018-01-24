module Services
  def self.statsd
    @statsd ||= begin
      statsd = Statsd.new
      statsd.namespace = "govuk.app.signon"
      statsd
    end
  end
end
