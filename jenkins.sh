#!/bin/bash -x
bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment
bundle exec rake stats
RAILS_ENV=test bundle exec rake db:drop db:create db:schema:load
USE_SIMPLECOV=true RAILS_ENV=test bundle exec rake ci:setup:minitest default
RESULT=$?
exit $RESULT