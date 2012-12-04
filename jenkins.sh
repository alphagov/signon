#!/bin/bash -x
bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment
govuk_setenv signon bundle exec rake stats
RAILS_ENV=test govuk_setenv signon bundle exec rake db:drop db:create db:schema:load
USE_SIMPLECOV=true RAILS_ENV=test govuk_setenv signon bundle exec rake --trace
RESULT=$?
exit $RESULT
