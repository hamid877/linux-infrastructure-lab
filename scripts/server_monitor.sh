#!/bin/bash

# =========================================
# Linux Infrastructure Lab - Server Monitor
# Version 2.0
# =========================================

# ---------- System Information ----------
HOSTNAME=$(hostname)
USER_NAME=$(whoami)
KERNEL=$(uname -r)
OS=$(hostnamectl | grep "Operating System" | cut -d':' -f2 | xargs)
UPTIME=$(uptime -p)

LOGFILE="$HOME/linux-lab/logs/server-health.log"

# ---------- Functions ----------

get_cpu_usage() {
    read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat

    idle1=$((idle + iowait))
    total1=$((user + nice + system + idle + iowait + irq + softirq + steal))

    sleep 1

    read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat

    idle2=$((idle + iowait))
    total2=$((user + nice + system + idle + iowait + irq + softirq + steal))

    idle_delta=$((idle2 - idle1))
    total_delta=$((total2 - total1))

    awk -v idle="$idle_delta" -v total="$total_delta" 'BEGIN {
        printf "%.1f", (100 * (total - idle) / total)
    }'
}

get_memory_usage() {
    free | awk '/Mem:/ {printf "%.1f", $3/$2 * 100}'
}

get_disk_usage() {
    df / | awk 'NR==2 {print $5}'
}

get_top_cpu_process() {
    ps -eo comm,%cpu --sort=-%cpu |
    awk '
        NR > 1 &&
        $1 !~ /^(ps|awk|grep|sed|bash|top|server_monitor\.)/ &&
        $1 !~ /^kworker/ &&
        $1 !~ /^migration/ &&
        $1 !~ /^rcu_/ &&
        $1 !~ /^systemd-hostnam/ {
            print $1 " (" $2 "%)"
            exit
        }'
}

get_top_mem_process() {
    ps -eo comm,%mem --sort=-%mem |
    awk 'NR==2 {print $1 " (" $2 "%)"}'
}

check_service() {
    if systemctl is-active --quiet "$1"; then
        echo "RUNNING"
    else
        echo "STOPPED"
    fi
}

health_status() {
    VALUE=$1
    WARNING=$2
    CRITICAL=$3

    if (( $(echo "$VALUE >= $CRITICAL" | bc -l) )); then
        echo "CRITICAL"
    elif (( $(echo "$VALUE >= $WARNING" | bc -l) )); then
        echo "WARNING"
    else
        echo "PASS"
    fi
}

# ---------- Collect Metrics ----------

CPU=$(get_cpu_usage)
MEM=$(get_memory_usage)
DISK=$(get_disk_usage)

DISK_VALUE=$(echo "$DISK" | tr -d '%')

CPU_STATUS=$(health_status "$CPU" 70 90)
MEM_STATUS=$(health_status "$MEM" 75 90)
DISK_STATUS=$(health_status "$DISK_VALUE" 80 90)

SSH_STATUS=$(check_service ssh)
NGINX_STATUS=$(check_service nginx)

TOP_CPU=$(get_top_cpu_process)
TOP_MEM=$(get_top_mem_process)

# ---------- Print Report ----------

echo "========================================="
echo "        SERVER HEALTH REPORT"
echo "========================================="
echo

printf "%-18s : %s\n" "Hostname" "$HOSTNAME"
printf "%-18s : %s\n" "User" "$USER_NAME"
printf "%-18s : %s\n" "Kernel" "$KERNEL"
printf "%-18s : %s\n" "Operating System" "$OS"
printf "%-18s : %s\n" "Uptime" "$UPTIME"

echo

printf "%-18s : %5s%% [%s]\n" "CPU Usage" "$CPU" "$CPU_STATUS"
printf "%-18s : %5s%% [%s]\n" "Memory Usage" "$MEM" "$MEM_STATUS"
printf "%-18s : %5s  [%s]\n" "Disk Usage" "$DISK" "$DISK_STATUS"

echo

printf "%-18s : %s\n" "Top CPU Process" "$TOP_CPU"
printf "%-18s : %s\n" "Top RAM Process" "$TOP_MEM"

echo

printf "%-18s : %s [%s]\n" \
    "SSH Service" \
    "$SSH_STATUS" \
    "$( [ "$SSH_STATUS" = "RUNNING" ] && echo PASS || echo CRITICAL )"

printf "%-18s : %s [%s]\n" \
    "Nginx Service" \
    "$NGINX_STATUS" \
    "$( [ "$NGINX_STATUS" = "RUNNING" ] && echo PASS || echo CRITICAL )"

echo
echo "========================================="

# ---------- Log Report ----------

mkdir -p "$(dirname "$LOGFILE")"

TIMESTAMP=$(date --iso-8601=seconds)

echo "$TIMESTAMP CPU=$CPU MEM=$MEM DISK=$DISK SSH=$SSH_STATUS NGINX=$NGINX_STATUS" >> "$LOGFILE"

exit 0
