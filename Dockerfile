FROM pihole/pihole

EXPOSE 53/tcp 53/udp 67/udp 80/tcp

ENV DNS1=127.0.0.1#5053
ENV DOH_DNS1=https://1.1.1.1/dns-query
ENV DOH_DNS2=https://1.0.0.1/dns-query

RUN apt-get update \
    && apt-get -y install wget \
    && ARCH=$(dpkg --print-architecture) \
    && case "$ARCH" in \
        "amd64") \
            DL_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb";; \
        "arm64") \
            DL_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb";; \
        "armhf"|"armv7l") \
            DL_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-armhf.deb";; \
        "armel") \
            DL_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm.deb";; \
        "i386") \
            DL_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386.deb";; \
        *) echo "Unsupported architecture"; exit 1;; \
    esac \
    && if [[ "$ARCH" = "i386" ]] ; then dpkg --add-architecture 386 ; fi \
    && if [[ "$ARCH" = "armel" ]] ; then dpkg --add-architecture arm ; fi \
    && wget -O cloudflared.deb "$DL_URL" \
    && apt-get -y purge wget \
    && apt-get install ./cloudflared.deb \
    && mkdir -p /etc/cloudflared/ \
    && mkdir -p /etc/s6-overlay/s6-rc.d/cloudflared/dependencies.d \
    && touch /etc/s6-overlay/s6-rc.d/cloudflared/type \
    && touch /etc/s6-overlay/s6-rc.d/cloudflared/run \
    && touch /etc/s6-overlay/s6-rc.d/cloudflared/dependencies.d/base \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/cloudflared \
    && echo 'longrun' >> /etc/s6-overlay/s6-rc.d/cloudflared/type \
    && echo -e '#!/command/with-contenv bash\ncloudflared proxy-dns --port 5053 --upstream $DOH_DNS1 --upstream $DOH_DNS2' >> /etc/s6-overlay/s6-rc.d/cloudflared/run

ENTRYPOINT /s6-init
