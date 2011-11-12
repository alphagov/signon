#!/bin/bash -x

export RAILS_ENV=test

bundle install --path "${HOME}/bundles/${JOB_NAME}"

# DELETE STATIC SYMLINKS AND RECONNECT...
for dir in images javascript templates stylesheets; do
  rm /var/lib/jenkins/jobs/Calendars/workspace/public/$dir
  ln -s /var/lib/jenkins/jobs/Static/workspace/public/$dir /var/lib/jenkins/jobs/Calendars/workspace/public/$dir
done

bundle exec rake stats
bundle exec rake ci:setup:testunit test
