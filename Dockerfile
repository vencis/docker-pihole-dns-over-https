FROM pihole/pihole

# Expose required ports
EXPOSE 53/tcp 53/udp 67/udp 80/tcp 443/tcp

# Configure DNS to use local cloudflared
ENV DNS1=127.0.0.1#5053
ENV DOH_DNS1=https://1.1.1.1/dns-query
ENV DOH_DNS2=https://1.0.0.1/dns-query

# Install cloudflared and bash for DNS-over-HTTPS
RUN apk add --no-cache wget bash \
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
    && apk del wget

# Copy scripts
COPY scripts/start-cloudflared.sh /usr/local/bin/
COPY scripts/custom-entrypoint.sh /usr/local/bin/

# Make scripts executable and install dig
RUN chmod +x /usr/local/bin/start-cloudflared.sh \
    && chmod +x /usr/local/bin/custom-entrypoint.sh \
    && apk add --no-cache bind-tools

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD dig @127.0.0.1 -p 5053 cloudflare.com || exit 1

ENTRYPOINT ["/usr/local/bin/custom-entrypoint.sh"]