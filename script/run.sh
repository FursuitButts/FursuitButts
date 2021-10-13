#!/usr/bin/env bash
APP_DIR=$1
PID_FILE=APP_DIR/tmp/pids/server.pid

cd $APP_DIR
sudo -i -u danbooru bash -c "/home/danbooru/ruby-setup.sh '$APP_DIR' '/etc/profile.d/chruby.sh'"
$APP_DIR/sh/compile
chown -R postgres:postgres /var/run/postgresql /var/lib/postgresql /etc/postgresql
chown -R danbooru:danbooru $APP_DIR
chown -R redis:redis /var/lib/redis


service redis start
service postgresql start
service nginx start

if [ -f $PID_FILE ]; then
    echo "Removing pid file.."
    rm $APP_DIR/tmp/pids/server.pid
fi

echo "Starting.."
sudo -i -u danbooru bash -c 'source /etc/profile.d/chruby.sh;cd /home/danbooru/danbooru;/usr/bin/shoreman'
