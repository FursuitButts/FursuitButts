#!/usr/bin/env bash

APP_DIR=/home/danbooru/danbooru
CHRUBY_PATH=/etc/profile.d/chruby.sh
VIPS_VERSION=8.10.5
RAILS_ENV=production
DEBIAN_FRONTEND=noninteractive
HOSTNAME="img.yiff.rest"

apt-get update -y
apt-get upgrade -y

DEBIAN_FRONTEND="noninteractive" TZ="America/Chicago" apt-get -y install tzdata ca-certificates wget curl git software-properties-common sudo
#curl https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py -o /usr/bin/systemctl

package_installed() {
    if dpkg-query -f '${binary:Package}\n' -W | grep "$1" &>/dev/null; then
        return 0;
    else
        return 1;
    fi
}

add_key() {
    wget -qO - "$1" | apt-key add - &>/dev/null
}

install_packages() {
    apt-get install -y $@
}

if ! grep danbooru /etc/passwd >/dev/null; then
    echo "Creating Danbooru User"
    useradd -s /bin/bash -U danbooru
    git clone https://github.com/DonovanDMC/e621ng /home/danbooru/danbooru
    chown -R danbooru:danbooru /home/danbooru
    echo "%danbooru ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/danbooru
    ln -s /home/danbooru/danbooru /vagrant
    usermod -aG www-data danbooru
fi

if ! package_installed postgresql-12; then
    add_key https://www.postgresql.org/media/keys/ACCC4CF8.asc
    echo "deb https://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
    echo "PostgreSQL repository added"
fi

if ! package_installed nodejs; then
    wget -qO - https://deb.nodesource.com/setup_14.x | sudo -E bash - >/dev/null 2>&1
    echo "Node.JS Repository Added"
fi

if ! package_installed yarn; then
    add_key https://dl.yarnpkg.com/debian/pubkey.gpg
    echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
    echo "Yarn Repository Added"
fi

apt-get update

if ! install_packages \
      build-essential automake libxml2-dev libxslt1-dev yarn nginx libncurses5-dev \
      libreadline-dev flex bison ragel libmemcached-dev git \
      libcurl4-openssl-dev nginx ssh libglib2.0-dev \
      mkvtoolnix cmake ffmpeg git libcurl4-openssl-dev ffmpeg postgresql-12 postgresql-server-dev-12 \
      libicu-dev libjpeg-progs libpq-dev libreadline-dev libxml2-dev \
      libexpat1-dev nodejs optipng redis-server \
      liblcms2-dev libjpeg-turbo8-dev libgif-dev libpng-dev libexif-dev; then
    >&2 echo "Installation of dependencies failed, please see the errors above and re-run the install script."
    exit 1
fi

echo "Setting up postgres..."
# allow connections from the host machine
if ! grep -q "172" "/etc/postgresql/12/main/pg_hba.conf"; then
  echo "host danbooru,danbooru2,danbooru3 danbooru 172.99.0.0/24 trust" >> /etc/postgresql/12/main/pg_hba.conf
  echo "host all all 172.31.0.1/32 trust"  >> /etc/postgresql/12/main/pg_hba.conf
fi
# do not require passwords for authentication
sed -i -e 's/md5/trust/' /etc/postgresql/12/main/pg_hba.conf
# listen for outside connections
echo "listen_addresses = '*'" > /etc/postgresql/12/main/conf.d/listen_addresses.conf

chown -R postgres:postgres /var/run/postgresql /var/lib/postgresql/12/main
if [ ! -f /usr/lib/postgresql/12/lib/test_parser.so ]; then
    echo "Building test_parser..."
    pushd .
    git clone https://github.com/r888888888/test_parser.git /tmp/test_parser
    cd /tmp/test_parser
    make install
    popd
    rm -fr /tmp/test_parser
fi

service postgresql restart

echo "Creating danbooru postgres user..."
sudo -u postgres createuser -s danbooru

if ! type ruby-install >/dev/null 2>&1; then
    echo "Installing Ruby"
    cd /usr/local/src
    wget -qO ruby-install-0.8.1.tar.gz https://github.com/postmodern/ruby-install/archive/v0.8.1.tar.gz
    tar -xzvf ruby-install-0.8.1.tar.gz >/dev/null
    cd ruby-install-0.8.1/
    make install >/dev/null
    rm /usr/local/src/ruby-install-0.8.1.tar.gz
fi

if [ -f "$CHRUBY_PATH" ]; then
    source $CHRUBY_PATH
fi

if ! type chruby >/dev/null 2>&1; then
    echo "Installing chruby"
    cd /usr/local/src
    wget -qO chruby-0.3.9.tar.gz https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz
    tar -xzvf chruby-0.3.9.tar.gz >/dev/null
    cd chruby-0.3.9/
    make install >/dev/null
    ./scripts/setup.sh >/dev/null
    rm /usr/local/src/chruby-0.3.9.tar.gz

    echo -e \
"if [ -n \"\$BASH_VERSION\" ] || [ -n \"\$ZSH_VERSION\" ]; then
  source /usr/local/share/chruby/chruby.sh
  source /usr/local/share/chruby/auto.sh
fi" > $CHRUBY_PATH
fi

if ! which vipsthumbnail >/dev/null; then
    echo "Installing libvips"
    pushd .
    cd /tmp
    wget -q https://github.com/libvips/libvips/releases/download/v$VIPS_VERSION/vips-$VIPS_VERSION.tar.gz
    tar xf vips-$VIPS_VERSION.tar.gz
    cd vips-$VIPS_VERSION
    ./configure --prefix=/usr
    make install
    ldconfig
    popd
    rm -rf /tmp/vips-$VIPS_VERSION.tar.gz /tmp/vips-$VIPS_VERSION
fi

echo "Enabling Redis Server"
chown -R redis:redis /var/lib/redis
systemctl enable redis-server 2>/dev/null
service redis-server start

cp /home/danbooru/danbooru/vagrant/ruby-setup-prod.sh /home/danbooru/ruby-setup.sh
SETUP_SCRIPT=/home/danbooru/ruby-setup.sh
chmod a+x $SETUP_SCRIPT
sudo -i -u danbooru bash -c "$SETUP_SCRIPT '$APP_DIR' '$CHRUBY_PATH'"

NGINX_CONFIG_PATH=/etc/nginx/conf.d/danbooru.conf
NGINX_DEFAULT_CONFIG_PATH=/etc/nginx/conf.d/default.conf
NGINX_DEFAULT_LISTENER_PATH=/etc/nginx/sites-enabled/default
echo "Linking nginx Config File"
if [ -f "$NGINX_CONFIG_PATH" ]; then
    rm "$NGINX_CONFIG_PATH"
fi
ln -s $APP_DIR/script/install/nginx.danbooru.conf "$NGINX_CONFIG_PATH"
sed -i -e 's/__hostname__/$HOSTNAME/' "$NGINX_CONFIG_PATH"
sed -i -e 's/root \/var\/www\/danbooru\/current\/public;/root \/home\/danbooru\/danbooru\/public;/' "$NGINX_CONFIG_PATH"
if [ -f "$NGINX_DEFAULT_CONFIG_PATH" ]; then
    rm "$NGINX_DEFAULT_CONFIG_PATH"
fi
if [ -f "$NGINX_DEFAULT_LISTENER_PATH" ]; then
    rm "$NGINX_DEFAULT_LISTENER_PATH"
fi
. /home/danbooru/danbooru/.env.local
if [ ! -d "/etc/ssl/local" ]; then
    (cd /etc/ssl; git clone https://DonovanDMC:$GIT_TOKEN@github.com/DonovanDMC/SSL local)
else
    (cd /etc/ssl/local; git pull)
fi;

service nginx restart

if [ ! -f /usr/bin/shoreman ]; then
    echo "Installing shoreman..."
    curl https://github.com/chrismytton/shoreman/raw/master/shoreman.sh -sLo /usr/bin/shoreman
    chmod +x /usr/bin/shoreman
else
    echo "Shoreman already installed, skipping.."
fi

PID_FILE=/home/danbooru/danbooru/tmp/pids/server.pid
if [ -f $PID_FILE ]; then
    echo "Removing pid file.."
    rm /home/danbooru/danbooru/tmp/pids/server.pid
fi

echo "Starting.."
sudo -i -u danbooru bash -c 'source /etc/profile.d/chruby.sh;cd /home/danbooru/danbooru;/usr/bin/shoreman'
