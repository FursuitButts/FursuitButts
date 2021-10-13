#!/usr/bin/env bash
APP_DIR=$1
PID_FILE=APP_DIR/tmp/pids/server.pid

cd $APP_DIR
sudo -i -u danbooru bash -c "/home/danbooru/ruby-setup.sh '$APP_DIR' '/etc/profile.d/chruby.sh'"
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
