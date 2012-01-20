#!/bin/bash -x

export RAILS_ENV=test

bundle install --path "${HOME}/bundles/${JOB_NAME}"

export DISPLAY=:99
bundle exec rake stats
bundle exec rake ci:setup:testunit test
