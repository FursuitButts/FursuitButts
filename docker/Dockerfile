FROM ubuntu:focal
ARG APP_DIR=/home/danbooru/danbooru
ARG CHRUBY_PATH=/etc/profile.d/chruby.sh
ARG VIPS_VERSION=8.10.5
ARG RAILS_ENV=production
ARG DEBIAN_FRONTEND=noninteractive
ARG HOSTNAME="yiff.rest"
ARG GH_REPO=https://github.com/DonovanDMC/e621ng
ARG RUBY_SETUP_SCRIPT=/home/danbooru/ruby-setup.sh
ARG NGINX_CONFIG_PATH=/etc/nginx/conf.d/danbooru.conf
ARG NGINX_DEFAULT_CONFIG_PATH=/etc/nginx/conf.d/default.conf
ARG NGINX_DEFAULT_LISTENER_PATH=/etc/nginx/sites-enabled/default

USER root
WORKDIR /
SHELL ["/bin/bash", "-c"]

RUN apt-get update -y && apt-get upgrade -y
RUN DEBIAN_FRONTEND="noninteractive" TZ="America/Chicago" apt-get -y install tzdata ca-certificates wget curl git software-properties-common sudo

# Danbooru
RUN useradd -s /bin/bash -U danbooru
RUN git clone $GH_REPO $APP_DIR
RUN chown -R danbooru:danbooru /home/danbooru
RUN echo "%danbooru ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/danbooru
RUN usermod -aG www-data danbooru

# PostgreSQL
RUN wget -qO - "https://www.postgresql.org/media/keys/ACCC4CF8.asc" | apt-key add - &>/dev/null
RUN echo "deb https://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# NodeJS
RUN wget -qO - https://deb.nodesource.com/setup_14.x | sudo -E bash - >/dev/null 2>&1

# Yarn
RUN wget -qO - "https://dl.yarnpkg.com/debian/pubkey.gpg" | apt-key add - &>/dev/null
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list

# Install Packages
RUN apt-get update
RUN apt-get install -y \
    build-essential automake libxml2-dev libxslt1-dev yarn \
    nginx libncurses5-dev libreadline-dev flex bison ragel \
    libmemcached-dev git libcurl4-openssl-dev nginx ssh \
    libglib2.0-dev mkvtoolnix cmake ffmpeg git \
    libcurl4-openssl-dev ffmpeg postgresql-12 \
    postgresql-server-dev-12 libicu-dev libjpeg-progs \
    libpq-dev libreadline-dev libxml2-dev libexpat1-dev \
    nodejs optipng redis-server liblcms2-dev \
    libjpeg-turbo8-dev libgif-dev libpng-dev libexif-dev

# PostgreSQL Setup
RUN echo "host danbooru,danbooru2,danbooru3 danbooru 172.99.0.0/24 trust" >> /etc/postgresql/12/main/pg_hba.conf
RUN echo "host all all 172.31.0.1/32 trust"  >> /etc/postgresql/12/main/pg_hba.conf
RUN sed -i -e 's/md5/trust/' /etc/postgresql/12/main/pg_hba.conf
RUN echo "listen_addresses = '*'" > /etc/postgresql/12/main/conf.d/listen_addresses.conf
RUN chown -R postgres:postgres /var/run/postgresql
RUN git clone https://github.com/r888888888/test_parser.git /tmp/test_parser
RUN cd /tmp/test_parser && make install
RUN rm -rf /tmp/test_parser
RUN service postgresql restart && sudo -u postgres createuser -s danbooru

# Ruby
WORKDIR /usr/local/src
RUN wget -qO ruby-install-0.8.1.tar.gz https://github.com/postmodern/ruby-install/archive/v0.8.1.tar.gz
RUN tar -xzvf ruby-install-0.8.1.tar.gz >/dev/null
RUN cd ruby-install-0.8.1/ && make install >/dev/null
RUN rm /usr/local/src/ruby-install-0.8.1.tar.gz

# ChRuby
WORKDIR /usr/local/src
RUN wget -qO chruby-0.3.9.tar.gz https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz
RUN tar -xzvf chruby-0.3.9.tar.gz >/dev/null
RUN cd chruby-0.3.9/ && make install >/dev/null && ./scripts/setup.sh >/dev/null
RUN rm /usr/local/src/chruby-0.3.9.tar.gz
RUN echo -e \
    "if [ -n \"\$BASH_VERSION\" ] || [ -n \"\$ZSH_VERSION\" ]; then \
      source /usr/local/share/chruby/chruby.sh \
      source /usr/local/share/chruby/auto.sh \
    fi" > $CHRUBY_PATH

# Vips
WORKDIR /tmp
RUN wget -q https://github.com/libvips/libvips/releases/download/v$VIPS_VERSION/vips-$VIPS_VERSION.tar.gz
RUN tar xf vips-$VIPS_VERSION.tar.gz
RUN cd vips-$VIPS_VERSION && ./configure --prefix=/usr && make install && ldconfig
RUN rm -rf /tmp/vips-$VIPS_VERSION.tar.gz /tmp/vips-$VIPS_VERSION
WORKDIR /

# Redis
RUN chown -R redis:redis /var/lib/redis
RUN service redis-server start

# More ruby nonsense
RUN cp /home/danbooru/danbooru/vagrant/ruby-setup-prod.sh /home/danbooru/ruby-setup.sh
RUN chmod a+x $SETUP_SCRIPT
RUN sudo -i -u danbooru bash -c "$SETUP_SCRIPT '$APP_DIR' '$CHRUBY_PATH'"

# Nginx
RUN rm -f "$NGINX_CONFIG_PATH"
RUN ln -s $APP_DIR/script/install/nginx.danbooru.conf "$NGINX_CONFIG_PATH"
RUN sed -i -e 's/__hostname__/$HOSTNAME/' "$NGINX_CONFIG_PATH"
RUN sed -i -e 's/root \/var\/www\/danbooru\/current\/public;/root \/home\/danbooru\/danbooru\/public;/' "$NGINX_CONFIG_PATH"
RUN rm -f "$NGINX_DEFAULT_CONFIG_PATH"
RUN rm -f "$NGINX_DEFAULT_LISTENER_PATH"
RUN source /home/danbooru/danbooru/.env.local && cd /etc/ssl && git clone https://DonovanDMC:$GIT_TOKEN@github.com/DonovanDMC/SSL local
RUN service nginx restart

# Install Shoreman
RUN curl https://github.com/chrismytton/shoreman/raw/master/shoreman.sh -sLo /usr/bin/shoreman && chmod +x /usr/bin/shoreman

USER danbooru
CMD $APP_DIR/script/run.sh $APP_DIR
