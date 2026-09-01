# Linux Infrastructure Lab

A hands-on Linux server administration and infrastructure project built on Ubuntu Server in a VirtualBox environment.

## Overview

This repository documents practical Linux administration labs focused on server operations, networking, monitoring, troubleshooting, automation, and web services.

The project simulates tasks commonly performed by Linux system administrators and data center technicians.

## Environment

* Host OS: Linux Mint
* Guest OS: Ubuntu Server 26.04 LTS
* Virtualization: Oracle VirtualBox
* Remote Access: OpenSSH

## Completed Labs

### Phase 1 — Linux Fundamentals

* User and group management
* File permissions and ownership
* Process management
* System logs with journalctl
* Basic Bash scripting

### Phase 2 — Networking Toolkit

* Network interface inspection
* IP and gateway discovery
* DNS validation
* Connectivity testing
* Listening port inspection

Scripts:

* `scripts/network_diagnostics.sh`

### Phase 3 — Nginx Server Operations

* Installed and configured Nginx.
* Validated configuration with `nginx -t`.
* Managed service lifecycle with `systemctl`.
* Investigated access and error logs.
* Built automated health-check script.

Scripts:

* `scripts/nginx_health_check.sh`

## Skills Demonstrated

* Linux CLI
* Bash scripting
* Systemd service management
* SSH administration
* Network troubleshooting
* HTTP service validation
* Log analysis

## Upcoming Modules

* Server monitoring toolkit
* Cron automation
* Disk and memory monitoring
* Prometheus Node Exporter
* Log rotation
* Incident response exercises
* Backup automation
