require "whenever"

# default cron env is "/usr/bin:/bin" which is not sufficient as govuk_setenv is in /usr/local/bin
env :PATH, "/usr/local/bin:/usr/bin:/bin"

set :output, error: "log/cron.error.log", standard: "log/cron.log"
job_type :rake, "cd :path && govuk_setenv signon bundle exec rake :task :output"

every 1.day, at: "1:15 am" do
  rake "event_log:delete_logs_older_than_two_years"
end
