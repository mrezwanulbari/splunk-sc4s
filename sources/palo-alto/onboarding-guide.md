# Palo Alto Networks — SC4S Onboarding Guide

## Overview

This guide covers onboarding Palo Alto Networks firewalls (PAN-OS) to Splunk via SC4S. PAN-OS is natively supported by SC4S and will auto-classify traffic, threat, system, and config logs.

## Prerequisites

- SC4S deployed and connected to Splunk HEC
- Splunk indexes created: `idx_firewall`, `idx_vpn`, `idx_authentication`
- Splunk Technology Add-on: [Splunk Add-on for Palo Alto Networks](https://splunkbase.splunk.com/app/2757/)
- Network connectivity from PAN-OS to SC4S (UDP/514 or TCP/514)

## Step 1: Configure PAN-OS Syslog Server Profile

```
Device → Server Profiles → Syslog
  Name:       SC4S-Primary
  Server:     <sc4s-ip-address>
  Transport:  TCP (recommended) or UDP
  Port:       514
  Format:     BSD
  Facility:   LOG_USER
```

## Step 2: Configure PAN-OS Log Forwarding Profile

```
Objects → Log Forwarding
  Name:       Forward-to-SC4S
  Log Type:   Traffic, Threat, URL, WildFire, Auth, System, Config
  Filter:     All Logs
  Syslog:     SC4S-Primary (from Step 1)
```

## Step 3: Apply to Security Policy Rules

```
Policies → Security → [each rule]
  Actions → Log Setting → Log Forwarding: Forward-to-SC4S
  ✓ Log at Session Start
  ✓ Log at Session End
```

## Step 4: Commit Changes

```
Commit → Commit (Full)
```

## Step 5: Update SC4S Index Mapping

Verify `splunk_metadata.csv` contains:

```csv
pan_traffic,index,idx_firewall
pan_threat,index,idx_firewall
pan_system,index,idx_firewall
pan_config,index,idx_firewall
pan_globalprotect,index,idx_vpn
pan_userid,index,idx_authentication
```

## Step 6: Validate in Splunk

```spl
index=idx_firewall sourcetype=pan:*
| stats count by sourcetype
| sort -count
```

### Expected Sourcetypes

| Sourcetype | Description |
|---|---|
| `pan:traffic` | Firewall traffic logs |
| `pan:threat` | Threat prevention logs |
| `pan:system` | System event logs |
| `pan:config` | Configuration change logs |
| `pan:globalprotect` | GlobalProtect VPN logs |
| `pan:userid` | User-ID mapping logs |

## Troubleshooting

| Issue | Solution |
|---|---|
| No data arriving | Check `docker logs sc4s` for errors |
| Wrong sourcetype | Verify PAN-OS format is set to BSD |
| Missing fields | Install Splunk Add-on for Palo Alto Networks |
| Duplicate events | Ensure only one syslog profile is configured |
