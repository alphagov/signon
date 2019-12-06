if File.exist?(Rails.root.join("REVISION"))
  revision = `cat #{Rails.root}/REVISION`.chomp
  CURRENT_RELEASE_SHA = revision[0..10] # Just get the short SHA
else
  CURRENT_RELEASE_SHA = "development".freeze
end
