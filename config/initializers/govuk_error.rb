GovukError.configure do |config|
  config.data_sync_excluded_exceptions << "Mysql2::Error"
end
