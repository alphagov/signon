#!/bin/bash -x

# This removes rbenv shims from the PATH where there is no
# .ruby-version file. This is because certain gems call their
# respective tasks with ruby -S which causes the following error to
# appear: ruby: no Ruby script found in input (LoadError).
if [ ! -f .ruby-version ]; then
  export PATH=`echo $PATH | awk 'BEGIN { RS=":"; ORS=":" } !/rbenv/' | sed 's/:$//'`
fi

export USE_SIMPLECOV=true
export RAILS_ENV=test
bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment
bundle exec rake stats
bundle exec rake db:drop db:create db:schema:load
bundle exec rake --trace
RESULT=$?
exit $RESULT
