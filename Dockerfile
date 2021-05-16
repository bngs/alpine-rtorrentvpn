FROM alpine:3.12

LABEL maintainer="bngs"

ENV UID=991
ENV GID=991
ENV RTORRENT_LISTEN_PORT=49314
ENV RTORRENT_DHT_PORT=49313
ENV DNS_SERVER_IP='9.9.9.9'


# Add flood configuration before build

RUN NB_CORES=${BUILD_CORES-$(getconf _NPROCESSORS_CONF)} \
  && addgroup -g ${GID} rtorrent \
  && adduser -h /home/rtorrent -s /bin/sh -G rtorrent -D -u ${UID} rtorrent \
  #&& build_pkgs="build-base git libtool automake autoconf tar xz binutils curl-dev cppunit-dev libressl-dev zlib-dev linux-headers ncurses-dev libxml2-dev" \
  && runtime_pkgs="supervisor shadow su-exec nginx ca-certificates php7 php7-fpm php7-json openvpn curl python2 ffmpeg sox unzip unrar git" \
  && apk -U upgrade \
  #&& apk add --no-cache --virtual=build-dependencies ${build_pkgs} \
  && apk add --no-cache ${runtime_pkgs}

# Install xmlrpc-c
  RUN apk add --upgrade xmlrpc-c

# Install libtorrent
  RUN apk add --upgrade libtorrent

# Install rtorrent
  RUN apk add --upgrade rtorrent
  RUN ln -s /usr/bin/rtorrent /usr/local/bin/rtorrent
  RUN which rtorrent

# Install mediainfo
  RUN apk add --upgrade mediainfo

# Install ruTorrent
  RUN apk add --upgrade rutorrent
  RUN mkdir /var/www/rutorrent/
  RUN mv /usr/share/webapps/rutorrent/* /var/www/rutorrent/
  RUN ls /var/www/rutorrent/
  #RUN ls /usr/share/webapps/rutorrent
  #RUN cat /usr/share/webapps/rutorrent/htaccess-example
# Add some extra stuff
  RUN git clone https://github.com/QuickBox/club-QuickBox /var/www/rutorrent/plugins/theme/themes/club-QuickBox \
  && git clone https://github.com/Phlooo/ruTorrent-MaterialDesign /var/www/webapps/rutorrent/plugins/theme/themes/MaterialDesign \
  && cd /var/www/webapps/rutorrent/plugins/ \
  && git clone https://github.com/xombiemp/rutorrentMobile \
  && git clone https://github.com/dioltas/AddZip \
  && chown -R rtorrent:rtorrent /var/www/rutorrent /home/rtorrent/

# Copy startup shells
COPY sh/* /usr/local/bin/

# Copy configuration files

# Set-up php-fpm
COPY config/php-fpm7_www.conf /etc/php7/php-fpm.d/www.conf
# Set-up nginx
COPY config/nginx.conf /etc/nginx/nginx.conf
# Configure supervisor
RUN sed -i -e "s/loglevel=info/loglevel=error/g" /etc/supervisord.conf
COPY config/rtorrentvpn_supervisord.conf /etc/supervisor.d/rtorrentvpn.ini

# Set-up rTorrent
COPY config/rtorrent.rc /home/rtorrent/rtorrent.rc
# Set-up ruTorrent
#COPY config/rutorrent_config.php /var/www/rutorrent/conf/config.php
RUN chown rtorrent:rtorrent /home/rtorrent/rtorrent.rc /var/www/rutorrent/conf/config.php
# COPY config/rutorrent_plugins.ini /var/www/rutorrent/conf/plugins.ini
# COPY config/rutorrent_autotools.dat /var/www/rutorrent/share/settings/autotools.dat
# RUN sed -i -e "s/\$autowatch_interval =.*/\$autowatch_interval = 10;/g" /var/www/rutorrent/plugins/autotools/conf.php

VOLUME /data /config

# WebUI
EXPOSE 8080

CMD ["supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf"]
