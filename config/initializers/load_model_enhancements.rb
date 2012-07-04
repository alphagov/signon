Dir[Rails.root.join("app", "models", "enhancements", "*.rb")].each do |path|
  name = File.basename(path, ".rb")
  require "enhancements/#{name}"
end
