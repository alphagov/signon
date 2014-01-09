# default cron env is "/usr/bin:/bin" which is not sufficient as govuk_env is in /usr/local/bin
env :PATH, '/usr/local/bin:/usr/bin:/bin'

set :output, {:error => 'log/cron.error.log', :standard => 'log/cron.log'}

# We need Rake to use our own environment
job_type :rake, "cd :path && govuk_setenv signon bundle exec rake :task :output"

every :day, at: '3am' do
  rake "organisations:fetch"
end

every :day, at: '2am' do
  rake "users:send_suspension_reminders"
end
