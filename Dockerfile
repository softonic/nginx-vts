ARG VERSION=1.17.3
FROM nginx:${VERSION}

ARG VERSION

LABEL com.softonic.logType="nginx-json"

ENV NGINX_VERSION=${VERSION}

RUN apt-get update &&\
 apt-get install -y build-essential git wget libpcre3 libpcre3-dev libssl-dev zlib1g-dev

RUN git clone git://github.com/vozlt/nginx-module-vts.git /tmp/nginx-module-vts &&\
 git clone git://github.com/openresty/headers-more-nginx-module /tmp/headers-more-nginx-module &&\
 wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz &&\
 tar -xzf nginx-${NGINX_VERSION}.tar.gz &&\
 cd nginx-${NGINX_VERSION} &&\
 ./configure\
 --prefix=/etc/nginx\
 --sbin-path=/usr/sbin/nginx\
 --modules-path=/usr/lib/nginx/modules\
 --conf-path=/etc/nginx/nginx.conf\
 --error-log-path=/var/log/nginx/error.log\
 --http-log-path=/var/log/nginx/access.log\
 --pid-path=/var/run/nginx.pid\
 --lock-path=/var/run/nginx.lock\
 --http-client-body-temp-path=/var/cache/nginx/client_temp\
 --http-proxy-temp-path=/var/cache/nginx/proxy_temp\
 --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp\
 --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp\
 --http-scgi-temp-path=/var/cache/nginx/scgi_temp\
 --user=nginx\
 --group=nginx\
 --with-compat\
 --with-file-aio\
 --with-threads\
 --with-http_addition_module\
 --with-http_auth_request_module\
 --with-http_dav_module\
 --with-http_flv_module\
 --with-http_gunzip_module\
 --with-http_gzip_static_module\
 --with-http_mp4_module\
 --with-http_random_index_module\
 --with-http_realip_module\
 --with-http_secure_link_module\
 --with-http_slice_module\
 --with-http_ssl_module\
 --with-http_stub_status_module\
 --with-http_sub_module\
 --with-http_v2_module\
 --with-mail\
 --with-mail_ssl_module\
 --with-stream\
 --with-stream_realip_module\
 --with-stream_ssl_module\
 --with-stream_ssl_preread_module\
 --with-cc-opt='-g -O2 -fdebug-prefix-map=/data/builder/debuild/nginx-${NGINX_VERSION}/debian/debuild-base/nginx-${NGINX_VERSION}=. -specs=/usr/share/dpkg/no-pie-compile.specs -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC'\
 --with-ld-opt='-specs=/usr/share/dpkg/no-pie-link.specs -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie'\
 --add-module=/tmp/nginx-module-vts\
 --add-module=/tmp/headers-more-nginx-module &&\
 make && make install

ADD ./rootfs/ /

ENTRYPOINT ["/bin/bash", "-c", "envsubst '${APPLICATION}' < /etc/nginx/conf.d/default.template > /etc/nginx/conf.d/00-default.conf && exec nginx -g 'daemon off;'"]

