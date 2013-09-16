#!/bin/bash -x

set -e

export USE_SIMPLECOV=true
export RAILS_ENV=test
bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment
bundle exec rake stats
bundle exec rake db:drop db:create db:schema:load
bundle exec rake --trace
