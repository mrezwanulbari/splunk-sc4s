# Fortinet FortiGate — SC4S Onboarding Guide

## Overview

Onboard FortiGate firewall logs (FortiOS) via SC4S. SC4S natively supports FortiGate traffic, UTM, and event logs.

## Prerequisites

- SC4S deployed and connected to Splunk HEC
- Splunk index: `idx_firewall`
- Splunk Technology Add-on: Fortinet FortiGate Add-on for Splunk

## Step 1: Configure FortiGate Syslog

```
config log syslogd setting
    set status enable
    set server "<sc4s-ip-address>"
    set port 514
    set reliable enable        # Use TCP
    set facility local7
    set format default
end
```

## Step 2: Enable Log Categories

```
config log syslogd filter
    set severity information
    set forward-traffic enable
    set local-traffic enable
    set multicast-traffic enable
    set sniffer-traffic enable
    set anomaly enable
    set dns enable
    set ssh enable
    set ssl enable
end
```

## Step 3: Validate in Splunk

```spl
index=idx_firewall sourcetype="fgt_traffic"
| stats count by action, srcip, dstip, dstport
| sort -count
```

### Expected Sourcetypes

| Sourcetype | Description |
|---|---|
| `fgt_traffic` | Firewall traffic logs |
| `fgt_utm` | UTM security inspection logs |
| `fgt_event` | System event logs |
