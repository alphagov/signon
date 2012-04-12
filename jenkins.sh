#!/bin/bash -x
bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment
RAILS_ENV=test bundle exec rake db:drop db:create db:schema:load
RAILS_ENV=test bundle exec rake --trace
