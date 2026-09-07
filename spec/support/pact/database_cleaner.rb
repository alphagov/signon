require "database_cleaner/active_record"

if ENV["DATABASE_URL"]
  DatabaseCleaner.url_allowlist = [
    %r{\Amysql2://root:root@mysql-8/signon_(?:development|test)\z},
  ]
end

DatabaseCleaner.strategy = :truncation
