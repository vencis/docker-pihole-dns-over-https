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

# Create cloudflared startup script
COPY <<-'EOF' /usr/local/bin/start-cloudflared.sh
#!/bin/bash
set -e

# Test DNS resolution before starting
if ! cloudflared proxy-dns --port 5053 --upstream $DOH_DNS1 --upstream $DOH_DNS2 --test-upstream; then
    echo "Error: Failed to resolve DNS using cloudflared"
    exit 1
fi

exec cloudflared proxy-dns --port 5053 --upstream $DOH_DNS1 --upstream $DOH_DNS2 --metrics localhost:49312
EOF

# Create custom entrypoint script
COPY <<-'EOF' /usr/local/bin/custom-entrypoint.sh
#!/bin/bash
set -e

# Handle shutdown
cleanup() {
    echo "Shutting down services..."
    kill -TERM $CLOUDFLARED_PID 2>/dev/null
    kill -TERM $PIHOLE_PID 2>/dev/null
    wait $CLOUDFLARED_PID 2>/dev/null
    wait $PIHOLE_PID 2>/dev/null
    exit 0
}
trap cleanup SIGTERM SIGINT

# Start services
echo "Starting cloudflared..."
/usr/local/bin/start-cloudflared.sh &
CLOUDFLARED_PID=$!

echo "Starting Pi-hole..."
/usr/bin/start.sh &
PIHOLE_PID=$!

# Wait for services to be ready
sleep 2

# Verify cloudflared is working
if ! dig @127.0.0.1 -p 5053 cloudflare.com > /dev/null; then
    echo "Error: cloudflared DNS resolution test failed"
    cleanup
    exit 1
fi

echo "Services started successfully"

# Monitor processes
while true; do
    if ! kill -0 $CLOUDFLARED_PID 2>/dev/null; then
        echo "Error: cloudflared exited unexpectedly"
        cleanup
        exit 1
    fi
    if ! kill -0 $PIHOLE_PID 2>/dev/null; then
        echo "Error: Pi-hole exited unexpectedly"
        cleanup
        exit 1
    fi
    sleep 1
done
EOF

# Make scripts executable
RUN chmod +x /usr/local/bin/start-cloudflared.sh \
    && chmod +x /usr/local/bin/custom-entrypoint.sh \
    && apk add --no-cache bind-tools

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD dig @127.0.0.1 -p 5053 cloudflare.com || exit 1

ENTRYPOINT ["/usr/local/bin/custom-entrypoint.sh"]