#!/bin/bash

# =========================================
# Linux Infrastructure Lab - Incident Toolkit
# Version 2.0
# =========================================

REPORT_DIR="$HOME/linux-lab/incident-toolkit/reports"
mkdir -p "$REPORT_DIR"

REPORT_FILE="$REPORT_DIR/incident-$(date +%F-%H%M%S).log"

# ---------- SSH Functions ----------

get_failed_login_count() {
    journalctl -u ssh --no-pager | grep -c "Failed password"
}

get_latest_failed_login() {
    journalctl -u ssh --no-pager | grep "Failed password" | tail -1
}

get_failed_user() {
    get_latest_failed_login | awk '
    {
        for (i=1; i<=NF; i++)
            if ($i=="for") {
                print $(i+1)
                exit
            }
    }'
}

get_failed_ip() {
    get_latest_failed_login | awk '
    {
        for (i=1; i<=NF; i++)
            if ($i=="from") {
                print $(i+1)
                exit
            }
    }'
}

# ---------- Nginx Functions ----------

get_nginx_error_count() {
    grep -c "\[error\]" /var/log/nginx/error.log 2>/dev/null
}

get_latest_nginx_error() {
    grep "\[error\]" /var/log/nginx/error.log 2>/dev/null | tail -1
}

check_nginx_permission_error() {
    if get_latest_nginx_error | grep -q "Permission denied"; then
        echo "WARNING"
    else
        echo "PASS"
    fi
}

# ---------- Service Functions ----------

get_failed_services() {
    systemctl --failed --no-legend
}

# ---------- Disk Functions ----------

check_disk_health() {
    USAGE=$(df / | awk 'NR==2 {gsub("%","",$5); print $5}')

    if [ "$USAGE" -ge 90 ]; then
        echo "CRITICAL"
    elif [ "$USAGE" -ge 80 ]; then
        echo "WARNING"
    else
        echo "PASS"
    fi
}

get_disk_usage() {
    df / | awk 'NR==2 {print $5}'
}

# ---------- Incident Severity ----------

OVERALL="PASS"

FAILED_SERVICES=$(get_failed_services)
SSH_COUNT=$(get_failed_login_count)
NGINX_STATUS=$(check_nginx_permission_error)
DISK_STATUS=$(check_disk_health)

# Critical conditions
if [ -n "$FAILED_SERVICES" ]; then
    OVERALL="CRITICAL"
fi

if [ "$DISK_STATUS" = "CRITICAL" ]; then
    OVERALL="CRITICAL"
fi

# Warning conditions (only if no critical issue exists)
if [ "$OVERALL" = "PASS" ]; then
    if [ "$SSH_COUNT" -ge 5 ]; then
        OVERALL="WARNING"
    fi

    if [ "$NGINX_STATUS" = "WARNING" ]; then
        OVERALL="WARNING"
    fi

    if [ "$DISK_STATUS" = "WARNING" ]; then
        OVERALL="WARNING"
    fi
fi

# ---------- Report ----------

{
echo "==========================================="
echo "        INCIDENT RESPONSE REPORT"
echo "==========================================="
echo

printf "%-18s : %s\n" "Generated" "$(date --iso-8601=seconds)"
printf "%-18s : %s\n" "Hostname" "$(hostname)"
printf "%-18s : %s\n" "Kernel" "$(uname -r)"
echo

printf "%-18s : %s\n" "OVERALL SEVERITY" "$OVERALL"

echo
echo "INCIDENT SUMMARY"
echo "----------------"

# Failed services
if [ -n "$FAILED_SERVICES" ]; then
    echo "CRITICAL  Failed systemd services detected."
else
    echo "PASS      No failed systemd services."
fi

# SSH
if [ "$SSH_COUNT" -gt 0 ]; then
    echo "WARNING   SSH authentication failures detected."
else
    echo "PASS      No SSH authentication failures."
fi

# Nginx
if [ "$NGINX_STATUS" = "WARNING" ]; then
    echo "WARNING   Nginx permission error detected."
else
    echo "PASS      No recent Nginx permission errors."
fi

# Disk
case "$DISK_STATUS" in
    PASS)
        echo "PASS      Disk usage normal ($(get_disk_usage))."
        ;;
    WARNING)
        echo "WARNING   Disk usage high ($(get_disk_usage))."
        ;;
    CRITICAL)
        echo "CRITICAL  Disk usage critically high ($(get_disk_usage))."
        ;;
esac

echo
echo "SSH ANALYSIS"
echo "------------"

printf "%-20s : %s\n" "Failed logins" "$SSH_COUNT"

if [ "$SSH_COUNT" -gt 0 ]; then
    printf "%-20s : %s\n" "Latest user" "$(get_failed_user)"
    printf "%-20s : %s\n" "Source IP" "$(get_failed_ip)"
    printf "%-20s : %s\n" "Latest event" "$(get_latest_failed_login)"
fi

echo
echo "NGINX ANALYSIS"
echo "--------------"

printf "%-20s : %s\n" "Recent errors" "$(get_nginx_error_count)"

LATEST_ERROR=$(get_latest_nginx_error)

if [ -n "$LATEST_ERROR" ]; then
    printf "%-20s : %s\n" "Severity" "$NGINX_STATUS"
    printf "%-20s : %s\n" "Latest error" "$LATEST_ERROR"
else
    echo "No recent Nginx errors."
fi

echo
echo "FAILED SERVICES"
echo "---------------"

if [ -n "$FAILED_SERVICES" ]; then
    echo "$FAILED_SERVICES"
else
    echo "None"
fi

echo
echo "DISK HEALTH"
echo "-----------"

df -h /

echo
echo "==========================================="

} | tee "$REPORT_FILE"
