#!/bin/bash
# =============================================================================
# SC4S Container Health Check Script
# =============================================================================
# Description: Monitors SC4S container health, HEC connectivity, and EPS
# Usage:       bash sc4s_health_check.sh
# =============================================================================

set -euo pipefail

SC4S_CONTAINER="${SC4S_CONTAINER_NAME:-sc4s}"
HEC_URL="${SC4S_DEST_SPLUNK_HEC_DEFAULT_URL:-https://localhost:8088}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# --- Check Container Status ---
check_container() {
    log "=== Container Status ==="
    if docker inspect "$SC4S_CONTAINER" --format='{{.State.Status}}' 2>/dev/null | grep -q "running"; then
        log "[OK] SC4S container is running"
        docker inspect "$SC4S_CONTAINER" --format='Uptime: {{.State.StartedAt}}'
    else
        log "[CRITICAL] SC4S container is NOT running!"
        return 1
    fi
}

# --- Check syslog-ng Process ---
check_syslog_ng() {
    log "=== syslog-ng Process ==="
    if docker exec "$SC4S_CONTAINER" supervisorctl status syslog-ng 2>/dev/null | grep -q "RUNNING"; then
        log "[OK] syslog-ng is running"
    else
        log "[CRITICAL] syslog-ng is NOT running inside container!"
        return 1
    fi
}

# --- Check HEC Connectivity ---
check_hec() {
    log "=== HEC Connectivity ==="
    local status
    status=$(curl -sk -o /dev/null -w "%{http_code}" "${HEC_URL}/services/collector/health")
    if [ "$status" = "200" ]; then
        log "[OK] HEC endpoint is healthy (HTTP $status)"
    else
        log "[WARNING] HEC endpoint returned HTTP $status"
    fi
}

# --- Check Port Listeners ---
check_ports() {
    log "=== Port Listeners ==="
    for port in 514 601 6514; do
        if docker exec "$SC4S_CONTAINER" ss -tlnp 2>/dev/null | grep -q ":${port}"; then
            log "[OK] TCP port $port is listening"
        else
            log "[WARNING] TCP port $port is NOT listening"
        fi
    done
}

# --- Check Container Resource Usage ---
check_resources() {
    log "=== Resource Usage ==="
    docker stats "$SC4S_CONTAINER" --no-stream --format \
        "CPU: {{.CPUPerc}} | Memory: {{.MemUsage}} | Net I/O: {{.NetIO}}"
}

# --- Main ---
main() {
    log "=========================================="
    log "  SC4S Health Check"
    log "=========================================="

    check_container
    check_syslog_ng
    check_hec
    check_ports
    check_resources

    log "=========================================="
    log "  Health check complete"
    log "=========================================="
}

main "$@"
