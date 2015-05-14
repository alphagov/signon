#!/bin/bash -x

set -e

git clean -fdx

export USE_SIMPLECOV=true
export RAILS_ENV=test
export DEVISE_SECRET_KEY=devise-test
bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment
bundle exec rake stats
bundle exec rake db:drop db:create db:schema:load
bundle exec rake --trace
