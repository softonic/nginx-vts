ARG VERSION=1.30.8
FROM nginx:${VERSION}-alpine AS builder

ARG VERSION
ARG VTS_VERSION=v0.2.7
ARG HEADERS_MORE_VERSION=v0.42
ARG NGX_BROTLI_COMMIT=53e0fb55f250f48fe80c0ddbf6c0f7103cdbaae1

RUN apk add --no-cache build-base git pcre2-dev openssl-dev zlib-dev linux-headers brotli-dev

RUN git clone --depth 1 --branch ${VTS_VERSION} https://github.com/vozlt/nginx-module-vts.git /tmp/nginx-module-vts \
 && git clone --depth 1 --branch ${HEADERS_MORE_VERSION} https://github.com/openresty/headers-more-nginx-module.git /tmp/headers-more-nginx-module \
 && git clone https://github.com/google/ngx_brotli.git /tmp/ngx_brotli \
 && git -C /tmp/ngx_brotli checkout ${NGX_BROTLI_COMMIT}

# ngx_brotli only builds against its vendored brotli submodule. Pointing that path at the
# Alpine package links the system brotli-libs instead, so the scanner sees it and apk patches it.
RUN mkdir -p /tmp/ngx_brotli/deps/brotli/c \
 && ln -s /usr/include /tmp/ngx_brotli/deps/brotli/c/include \
 && ln -s /usr/lib /tmp/ngx_brotli/deps/brotli/out

# Same configure arguments as the official binary, minus its dynamic modules (they are not
# loaded and would need extra -dev packages), so paths, user and features stay identical.
RUN wget -q https://nginx.org/download/nginx-${VERSION}.tar.gz -O /tmp/nginx.tar.gz \
 && tar -xzf /tmp/nginx.tar.gz -C /tmp \
 && cd /tmp/nginx-${VERSION} \
 && CONFARGS=$(nginx -V 2>&1 | sed -n 's/^configure arguments: //p' | sed -E "s/--with-[a-z_]+=dynamic//g") \
 && eval ./configure ${CONFARGS} \
    --add-module=/tmp/nginx-module-vts \
    --add-module=/tmp/headers-more-nginx-module \
    --add-module=/tmp/ngx_brotli \
 && make -j"$(nproc)" \
 && make install

FROM nginx:${VERSION}-alpine AS runtime

LABEL com.softonic.logType="nginx-json"

RUN apk add --no-cache bash brotli-libs \
 && apk upgrade --no-cache

COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx

ADD ./rootfs/ /

ENTRYPOINT ["/bin/bash", "-c", "cat /etc/nginx/conf.d/*.template | envsubst '${APPLICATION}' > /etc/nginx/conf.d/00-default.conf && exec nginx -g 'daemon off;'"]
