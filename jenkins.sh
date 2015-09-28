#!/bin/bash -x

set -e

git clean -fdx

export RAILS_ENV=test
bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment

if [[ ${GIT_BRANCH} != "origin/master" ]]; then
  bundle exec govuk-lint-ruby \
    --format html --out rubocop-${GIT_COMMIT}.html \
    --format clang \
    app test lib spec config
fi

bundle exec rake stats
bundle exec rake db:drop db:create db:schema:load
bundle exec rake --trace
