FROM container4armhf/armhf-alpine:edge
ENV IP_BROADCAST="172.16.0.255" PHP_FPM_USER="www" PHP_FPM_GROUP="www" PHP_FPM_LISTEN_MODE="0660"
# use the CDN mirror from gilderlabs since its much faster
RUN mkdir -p /etc/apk && echo "http://alpine.gliderlabs.com/alpine/edge/main" > /etc/apk/repositories &&\
# Install openrc
    apk update && apk add openrc &&\
# Tell openrc its running inside a container, till now that has meant LXC
    sed -i 's/#rc_sys=""/rc_sys="lxc"/g' /etc/rc.conf &&\
# Tell openrc loopback and net are already there, since docker handles the networking
    echo 'rc_provide="loopback net"' >> /etc/rc.conf &&\
# no need for loggers
    sed -i 's/^#\(rc_logger="YES"\)$/\1/' /etc/rc.conf &&\
# can't get ttys unless you run the container in privileged mode
    sed -i '/tty/d' /etc/inittab &&\
# can't set hostname since docker sets it
    sed -i 's/hostname $opts/# hostname $opts/g' /etc/init.d/hostname &&\
# can't mount tmpfs since not privileged
    sed -i 's/mount -t tmpfs/# mount -t tmpfs/g' /lib/rc/sh/init.sh &&\
# can't do cgroups
    sed -i 's/cgroup_add_service /# cgroup_add_service /g' /lib/rc/sh/openrc-run.sh && \

# alpine does not have php sockets installed by default
    apk add nginx php5-cli php5-fpm php5-sockets git && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    echo -e '\n# Mitigate httpoxy attack\nfastcgi_param  HTTP_PROXY         "";' >> /etc/nginx/fastcgi_params && \
    mkdir /opt && cd /opt && \
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig && \
    git clone https://github.com/fernadosilva/orvfms.git && \
    rm -rf orvfms/.git && \
    sed -ri "s/192.168.1.255/${IP_BROADCAST}/" orvfms/lib/orvfms/globals.php

COPY resources/nginx.conf /etc/nginx/nginx.conf
RUN    adduser -D -u 1000 -g 'www' www && \
       chown -R www:www /opt/orvfms && \
       sed -i "s|;listen.owner\s*=\s*nobody|listen.owner = ${PHP_FPM_USER}|g" /etc/php5/php-fpm.conf && \
       sed -i "s|;listen.group\s*=\s*nobody|listen.group = ${PHP_FPM_GROUP}|g" /etc/php5/php-fpm.conf && \
       sed -i "s|;listen.mode\s*=\s*0660|listen.mode = ${PHP_FPM_LISTEN_MODE}|g" /etc/php5/php-fpm.conf && \
       sed -i "s|user\s*=\s*nobody|user = ${PHP_FPM_USER}|g" /etc/php5/php-fpm.conf && \
       sed -i "s|group\s*=\s*nobody|group = ${PHP_FPM_GROUP}|g" /etc/php5/php-fpm.conf && \
       sed -i "s|listen\s*=\s*127.0.0.1:9000|listen = /var/run/php5-fpm.socket|" /etc/php5/php-fpm.conf && \
       sed -i "s|user\s*nginx|user       ${PHP_FPM_USER}|g" /etc/nginx/nginx.conf && \
       rc-update add nginx default && \
       rc-update add php-fpm default
WORKDIR /opt/orvfms

EXPOSE 80

CMD ["/sbin/init"]
