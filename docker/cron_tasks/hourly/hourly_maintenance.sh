#!/usr/bin/env sh
echo "Running hourly maintenance"
cd /app && bundle exec rake maintenance:hourly
echo "Finished hourly maintenance"
