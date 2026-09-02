#!/bin/bash

echo "===== NGINX HEALTH CHECK ====="

if systemctl is-active --quiet nginx; then
    echo "Service Status : PASS"
else
    echo "Service Status : FAIL"
fi

if sudo ss -tlpn | grep -q ":80"; then
    echo "Port 80        : PASS"
else
    echo "Port 80        : FAIL"
fi

STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)

if [ "$STATUS" = "200" ]; then
    echo "HTTP Response  : PASS (200 OK)"
else
    echo "HTTP Response  : FAIL ($STATUS)"
fi
