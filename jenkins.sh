#!/bin/bash -x
bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment
govuk_setenv signon bundle exec rake stats
govuk_setenv signon bundle exec rake db:drop db:create db:schema:load
govuk_setenv signon env USE_SIMPLECOV=true RAILS_ENV=test bundle exec rake --trace 
RESULT=$?
exit $RESULT
