#!/bin/bash
set -e

# Test DNS resolution before starting
if ! cloudflared proxy-dns --port 5053 --upstream $DOH_DNS1 --upstream $DOH_DNS2 --test-upstream; then
    echo "Error: Failed to resolve DNS using cloudflared"
    exit 1
fi

exec cloudflared proxy-dns --port 5053 --upstream $DOH_DNS1 --upstream $DOH_DNS2 --metrics localhost:49312 