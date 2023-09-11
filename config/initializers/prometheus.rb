require "govuk_app_config/govuk_prometheus_exporter"
require "collectors/global_prometheus_collector"

GovukPrometheusExporter.configure(collectors: [Collectors::GlobalPrometheusCollector])
