FROM pihole/pihole

EXPOSE 53/tcp 53/udp 67/udp 80/tcp

ENV DNS1=127.0.0.1#5053
ENV DOH_DNS1=https://1.1.1.1/dns-query
ENV DOH_DNS2=https://1.0.0.1/dns-query

RUN apk add --no-cache wget \
    && ARCH=$(uname -m) \
    && case "$ARCH" in \
        "x86_64") \
            DL_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64";; \
        "aarch64") \
            DL_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64";; \
        "armv7l") \
            DL_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-armhf";; \
        "armv6l") \
            DL_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm";; \
        "i386"|"i686") \
            DL_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386";; \
        *) echo "Unsupported architecture"; exit 1;; \
    esac \
    && wget -O /usr/local/bin/cloudflared "$DL_URL" \
    && chmod +x /usr/local/bin/cloudflared \
    && apk del wget \
    && mkdir -p /etc/cloudflared/ /etc/s6-overlay/s6-rc.d/cloudflared/dependencies.d \
    && touch /etc/s6-overlay/s6-rc.d/cloudflared/dependencies.d/base \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/cloudflared \
    && echo 'longrun' > /etc/s6-overlay/s6-rc.d/cloudflared/type \
    && echo '#!/command/with-contenv sh\ncloudflared proxy-dns --port 5053 --upstream $DOH_DNS1 --upstream $DOH_DNS2' > /etc/s6-overlay/s6-rc.d/cloudflared/run \
    && chmod +x /etc/s6-overlay/s6-rc.d/cloudflared/run

ENTRYPOINT ["/init"]