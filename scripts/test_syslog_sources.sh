#!/bin/bash
# =============================================================================
# SC4S Syslog Source Connectivity Test
# =============================================================================
# Description: Sends test syslog messages to SC4S for validation
# Usage:       bash test_syslog_sources.sh <sc4s-host>
# =============================================================================

SC4S_HOST="${1:-localhost}"
SC4S_PORT="${2:-514}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

send_test() {
    local protocol="$1"
    local description="$2"
    local message="$3"

    log "Testing: $description ($protocol)"
    if [ "$protocol" = "udp" ]; then
        echo "$message" | nc -u -w1 "$SC4S_HOST" "$SC4S_PORT"
    else
        echo "$message" | nc -w1 "$SC4S_HOST" "$SC4S_PORT"
    fi
}

log "=========================================="
log "  SC4S Source Connectivity Tests"
log "  Target: $SC4S_HOST:$SC4S_PORT"
log "=========================================="

# --- Generic Syslog Test ---
send_test "udp" "Generic Syslog (RFC 3164)" \
    '<134>Jan 15 10:30:00 testhost testapp[1234]: SC4S connectivity test message'

# --- Cisco ASA Format ---
send_test "tcp" "Cisco ASA" \
    '<166>Jan 15 10:30:00 asa-fw-01 %ASA-6-302013: Built inbound TCP connection 12345 for outside:10.0.0.1/54321 (10.0.0.1/54321) to inside:192.168.1.1/443 (192.168.1.1/443)'

# --- Palo Alto Traffic ---
send_test "tcp" "Palo Alto Traffic" \
    '<14>1 2024-01-15T10:30:00.000Z pa-fw-01 - - - - 1,2024/01/15 10:30:00,001234567890,TRAFFIC,end,2560,2024/01/15 10:30:00,10.0.0.1,192.168.1.1,0.0.0.0,0.0.0.0,allow-all,,,web-browsing,vsys1,trust,untrust,ethernet1/1,ethernet1/2,Forward-Logs,2024/01/15 10:30:00,12345,1,54321,443,0,0,0x0,tcp,allow,1234,1000,234,10,2024/01/15 10:30:00,0,any,0,67890,0x0,10.0.0.0-10.255.255.255,192.168.0.0-192.168.255.255,0,8,2,aged-out,0,0,0,0,,pa-fw-01,from-policy'

# --- Fortinet FortiGate ---
send_test "tcp" "Fortinet FortiGate" \
    '<134>date=2024-01-15 time=10:30:00 devname="fg-fw-01" devid="FG100E1234567890" logid="0000000013" type="traffic" subtype="forward" level="notice" vd="root" srcip=10.0.0.1 srcport=54321 dstip=192.168.1.1 dstport=443 action="accept"'

# --- Linux Auth ---
send_test "udp" "Linux Authentication" \
    '<86>Jan 15 10:30:00 linux-srv-01 sshd[12345]: Accepted publickey for admin from 10.0.0.100 port 22 ssh2'

log "=========================================="
log "  Tests complete!"
log "  Check Splunk: index=* \"SC4S connectivity test\" OR sourcetype=cisco:asa OR sourcetype=pan:traffic"
log "=========================================="
