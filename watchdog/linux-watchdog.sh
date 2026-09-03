#!/bin/bash
set -euo pipefail

# ==========================================
# Linux Watchdog Daemon
# Linux Infrastructure Lab
# Author: Hamid
# ==========================================

# ---------- Configuration ----------

LOG_DIR="$HOME/linux-lab/watchdog/logs"
LOG_FILE="$LOG_DIR/watchdog.log"

INTERVAL=30

CPU_WARNING=70
CPU_CRITICAL=90

MEM_WARNING=75
MEM_CRITICAL=90

DISK_WARNING=80
DISK_CRITICAL=90

mkdir -p "$LOG_DIR"

# ---------- Graceful Shutdown ----------

cleanup() {
    log INFO "Linux Watchdog shutting down."
    exit 0
}

trap cleanup SIGINT SIGTERM

# ---------- Logging ----------

log() {
    local LEVEL="$1"
    local MESSAGE="$2"

    local TIMESTAMP
    TIMESTAMP=$(date "+%F %T")

    echo "$TIMESTAMP | $LEVEL | $MESSAGE" | tee -a "$LOG_FILE"
}

# ---------- Metric Collection ----------

get_cpu_usage() {
    top -bn1 | awk '/Cpu\(s\)/ {printf "%.1f", 100 - $8}'
}

get_memory_usage() {
    free | awk '/Mem:/ {printf "%.1f", $3/$2 * 100}'
}

get_disk_usage() {
    df / | awk 'NR==2 {gsub("%",""); print $5}'
}

check_service() {
    local SERVICE="$1"

    if systemctl is-active --quiet "$SERVICE"; then
        echo "RUNNING"
    else
        echo "STOPPED"
    fi
}

# ---------- Health Evaluation ----------

health_status() {
    local VALUE="$1"
    local WARNING="$2"
    local CRITICAL="$3"

    if (( $(echo "$VALUE >= $CRITICAL" | bc -l) )); then
        echo "CRITICAL"
    elif (( $(echo "$VALUE >= $WARNING" | bc -l) )); then
        echo "WARNING"
    else
        echo "PASS"
    fi
}

# ---------- Startup ----------

log INFO "Linux Watchdog started."

# ---------- Main Monitoring Loop ----------

while true
do
    CPU=$(get_cpu_usage)
    MEM=$(get_memory_usage)
    DISK=$(get_disk_usage)

    CPU_STATE=$(health_status "$CPU" "$CPU_WARNING" "$CPU_CRITICAL")
    MEM_STATE=$(health_status "$MEM" "$MEM_WARNING" "$MEM_CRITICAL")
    DISK_STATE=$(health_status "$DISK" "$DISK_WARNING" "$DISK_CRITICAL")

    SSH_STATE=$(check_service ssh)
    NGINX_STATE=$(check_service nginx)

    # ----- Resource Alerts -----

    if [ "$CPU_STATE" = "WARNING" ]; then
        log WARNING "CPU usage is high (${CPU}%)."
    elif [ "$CPU_STATE" = "CRITICAL" ]; then
        log ERROR "CPU usage is CRITICAL (${CPU}%)."
    fi

    if [ "$MEM_STATE" = "WARNING" ]; then
        log WARNING "Memory usage is high (${MEM}%)."
    elif [ "$MEM_STATE" = "CRITICAL" ]; then
        log ERROR "Memory usage is CRITICAL (${MEM}%)."
    fi

    if [ "$DISK_STATE" = "WARNING" ]; then
        log WARNING "Disk usage is high (${DISK}%)."
    elif [ "$DISK_STATE" = "CRITICAL" ]; then
        log ERROR "Disk usage is CRITICAL (${DISK}%)."
    fi

    # ----- Service Alerts -----

    if [ "$SSH_STATE" != "RUNNING" ]; then
        log ERROR "SSH service is DOWN."
    fi

    if [ "$NGINX_STATE" != "RUNNING" ]; then
        log ERROR "Nginx service is DOWN."
    fi

    # ----- Heartbeat -----

    log INFO "Heartbeat | CPU=${CPU}% [$CPU_STATE] | MEM=${MEM}% [$MEM_STATE] | DISK=${DISK}% [$DISK_STATE] | SSH=$SSH_STATE | NGINX=$NGINX_STATE"

    sleep "$INTERVAL"
done
