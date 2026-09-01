#!/bin/bash

HOSTNAME=$(hostname)
USER_NAME=$(whoami)
KERNEL=$(uname -r)
OS=$(hostnamectl | grep "Operating System" | cut -d':' -f2 | xargs)
UPTIME=$(uptime -p)

get_cpu_usage() {
    top -bn1 | awk '/Cpu\(s\)/ {printf "%.1f", 100 - $8}'
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
        NR>1 &&
        $1 !~ /^(ps|awk|grep|sed|bash|top|kworker|migration|rcu_.*|systemd-hostnam)$/ {
            print $1 " (" $2 "%)"
            exit
        }'
}

get_top_mem_process() {
    ps -eo comm,%mem --sort=-%mem | awk 'NR==2 {print $1 " (" $2 "%)"}'
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

CPU=$(get_cpu_usage)
MEM=$(get_memory_usage)
DISK=$(get_disk_usage)
CPU_STATUS=$(health_status "$CPU" 70 90)
MEM_STATUS=$(health_status "$MEM" 75 90)
DISK_VALUE=$(echo "$DISK" | tr -d '%')
DISK_STATUS=$(health_status "$DISK_VALUE" 80 90)


echo "========================================="
echo "        SERVER HEALTH REPORT"
echo "========================================="
echo
echo "Hostname          : $HOSTNAME"
echo "User              : $USER_NAME"
echo "Kernel            : $KERNEL"
echo "Operating System  : $OS"
echo "Uptime            : $UPTIME"
echo
echo "CPU Usage         : ${CPU}%"
echo "Memory Usage      : ${MEM}%"
echo "Disk Usage        : $DISK"
echo
echo "Top CPU Process   : $(get_top_cpu_process)"
echo "Top RAM Process   : $(get_top_mem_process)"
echo
echo "SSH Service       : $(check_service ssh)"
echo "Nginx Service     : $(check_service nginx)"
echo
echo "========================================="


LOGFILE=~/linux-lab/logs/server-health.log

{
    echo "===== $(date) ====="
    echo "Hostname : $HOSTNAME"
    echo "CPU      : ${CPU}%"
    echo "Memory   : ${MEM}%"
    echo "Disk     : $DISK"
    echo "SSH      : $(check_service ssh)"
    echo "Nginx    : $(check_service nginx)"
    echo
} >> "$LOGFILE"

