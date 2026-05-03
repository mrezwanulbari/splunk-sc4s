# Cisco ASA / FTD — SC4S Onboarding Guide

## Overview

Onboard Cisco ASA and Firepower Threat Defense (FTD) logs via SC4S. Both are natively supported with full field extraction.

## Prerequisites

- SC4S deployed and connected to Splunk HEC
- Splunk index: `idx_network_security`
- Splunk Technology Add-on: Cisco Security Suite or Splunk Add-on for Cisco ASA

## Step 1: Configure Cisco ASA Logging

```
logging enable
logging timestamp
logging trap informational
logging host inside <sc4s-ip-address> TCP/514
logging permit-hostdown

! EMBLEM format for optimal SC4S parsing
logging device-id hostname
```

## Step 2: Configure FTD (via FMC)

```
Devices → Platform Settings → Syslog
  Logging Server: <sc4s-ip-address>
  Protocol:       TCP
  Port:           514
  Facility:       LOCAL4
```

## Step 3: Validate in Splunk

```spl
index=idx_network_security sourcetype="cisco:asa"
| stats count by action, src_ip, dest_ip
| sort -count
```

### Expected Sourcetypes

| Sourcetype | Description |
|---|---|
| `cisco:asa` | ASA firewall events |
| `cisco:ftd` | FTD threat events |

## Key ASA Message IDs for Security Monitoring

| Message ID | Description | Severity |
|---|---|---|
| %ASA-4-106023 | Denied packet | Warning |
| %ASA-6-302013 | Built TCP connection | Informational |
| %ASA-6-302014 | Teardown TCP connection | Informational |
| %ASA-4-733100 | Threat detection rate limit | Warning |
| %ASA-3-710003 | Connection denied | Error |
| %ASA-6-605005 | Login permitted | Informational |
| %ASA-4-405001 | ARP collision detected | Warning |
