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