#!/usr/bin/env bash
APP_DIR=$1
PID_FILE=$APP_APP_DIR/tmp/pids/server.pid

cd $APP_DIR
$APP_DIR/sh/compile
service redis start
service postgresql start
service nginx start

if [ -f $PID_FILE ]; then
    echo "Removing pid file.."
    rm /home/danbooru/danbooru/tmp/pids/server.pid
fi

echo "Starting.."
sudo -i -u danbooru bash -c 'source /etc/profile.d/chruby.sh;cd /home/danbooru/danbooru;/usr/bin/shoreman'
