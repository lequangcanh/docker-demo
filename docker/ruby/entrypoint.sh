#!/bin/bash

set -e
bundle check || bundle install --binstubs="$BUNDLE_BIN"

bundle exec rake db:create
bundle exec rake db:migrate

rm -f tmp/pids/server.pid

bundle exec rails assets:precompile
bundle exec rails server -b 0.0.0.0

exec "$@"
