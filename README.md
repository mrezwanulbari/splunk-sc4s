# Splunk Connect for Syslog (SC4S) — Enterprise Syslog Collection

![Splunk](https://img.shields.io/badge/Splunk-000000?style=for-the-badge&logo=splunk&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green.svg)

> Production-grade SC4S deployment guides, source configurations, custom parsers, and log onboarding playbooks for enterprise syslog collection at scale.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Quick Start](#quick-start)
- [Source Onboarding](#source-onboarding)
- [Custom Log Paths](#custom-log-paths)
- [Performance Tuning](#performance-tuning)
- [High Availability](#high-availability)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

---

## Overview

**SC4S (Splunk Connect for Syslog)** is a containerized syslog-ng solution that provides reliable, high-performance syslog collection for Splunk. It automatically parses, classifies, and routes syslog data to the correct Splunk index and sourcetype.

### Why SC4S?

| Feature | Benefit |
|---|---|
| **Auto-classification** | Automatically identifies 200+ syslog sources |
| **Containerized** | Docker/Podman deployment with minimal footprint |
| **HEC Integration** | Sends data via HTTP Event Collector for reliability |
| **Compliance** | Ensures consistent log collection for regulatory frameworks |
| **Scalability** | Handles 50,000+ EPS per instance |

### Supported Sources (Partial List)

| Category | Sources |
|---|---|
| **Firewalls** | Palo Alto, Cisco ASA/FTD, Fortinet, Check Point, Juniper SRX |
| **Network** | Cisco IOS/NX-OS, Arista, F5 BIG-IP, Aruba, Brocade |
| **Security** | CrowdStrike, Carbon Black, Symantec, McAfee, Trend Micro |
| **Identity** | Cisco ISE, Aruba ClearPass, FreeRADIUS |
| **Infrastructure** | VMware ESXi/vCenter, NetApp, Nutanix, Dell iDRAC |
| **Linux/Unix** | syslog, auditd, journald, authlog |

---

## Architecture

### Single-Instance Deployment

```
┌─────────────────────────────────────────────────────────┐
│                    Network Sources                       │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐         │
│  │ FW   │ │Switch│ │ IDS  │ │ WAF  │ │ ESXi │         │
│  └──┬───┘ └──┬───┘ └──┬───┘ └──┬───┘ └──┬───┘         │
└─────┼────────┼────────┼────────┼────────┼───────────────┘
      │UDP/514 │TCP/514 │TCP/601 │TCP/6514│UDP/514
      │        │        │        │(TLS)   │
┌─────▼────────▼────────▼────────▼────────▼───────────────┐
│                  SC4S Container                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │              syslog-ng engine                    │    │
│  │  ┌──────────┐ ┌───────────┐ ┌─────────────┐    │    │
│  │  │  Parser  │ │ Classifier│ │   Router     │    │    │
│  │  │  Engine  │ │  (Filter) │ │  (Index Map) │    │    │
│  │  └──────────┘ └───────────┘ └──────┬──────┘    │    │
│  └────────────────────────────────────┼────────────┘    │
│                                       │ HEC              │
└───────────────────────────────────────┼─────────────────┘
                                        │
┌───────────────────────────────────────▼─────────────────┐
│              Splunk Indexer Cluster                       │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                 │
│  │  IDX-1  │  │  IDX-2  │  │  IDX-3  │                 │
│  └─────────┘  └─────────┘  └─────────┘                 │
└─────────────────────────────────────────────────────────┘
```

### Multi-Instance HA Deployment

```
                    ┌──────────────┐
                    │ Load Balancer│
                    │ (F5/HAProxy) │
                    └───┬──────┬───┘
                        │      │
              ┌─────────▼─┐  ┌─▼─────────┐
              │   SC4S-1   │  │   SC4S-2   │
              │ (Active)   │  │ (Active)   │
              └─────┬──────┘  └──────┬─────┘
                    │                │
                    └───────┬────────┘
                            │ HEC
                    ┌───────▼────────┐
                    │  Splunk HEC    │
                    │  Endpoint(s)   │
                    └────────────────┘
```

---

## Repository Structure

```
splunk-sc4s/
├── README.md
├── docker-compose.yml
├── .env.example
├── configs/
│   ├── env_file                       # SC4S environment variables
│   ├── context/
│   │   ├── splunk_metadata.csv        # Source-to-index/sourcetype mapping
│   │   ├── vendor_product_by_source.csv  # Custom source identification
│   │   └── vendor_product_by_source.conf # syslog-ng filter overrides
│   └── local/
│       ├── context/
│       │   └── splunk_metadata.csv    # Local overrides
│       └── config/
│           └── addons/                # Custom log path addons
├── sources/
│   ├── palo-alto/                     # Palo Alto Networks onboarding
│   │   ├── README.md
│   │   └── onboarding-guide.md
│   ├── cisco-asa/                     # Cisco ASA/FTD onboarding
│   │   ├── README.md
│   │   └── onboarding-guide.md
│   ├── fortinet/                      # Fortinet FortiGate onboarding
│   │   ├── README.md
│   │   └── onboarding-guide.md
│   ├── cisco-ios/                     # Cisco IOS/NX-OS onboarding
│   │   ├── README.md
│   │   └── onboarding-guide.md
│   ├── linux-syslog/                  # Linux syslog onboarding
│   │   ├── README.md
│   │   └── onboarding-guide.md
│   └── vmware/                        # VMware ESXi/vCenter onboarding
│       ├── README.md
│       └── onboarding-guide.md
├── custom-parsers/
│   ├── README.md
│   ├── custom_app_parser.conf         # Example custom parser
│   └── custom_filter_template.conf    # Filter template
├── scripts/
│   ├── sc4s_health_check.sh           # Container health monitoring
│   ├── test_syslog_sources.sh         # Test syslog connectivity
│   └── hec_token_setup.sh             # Automate HEC token creation
├── monitoring/
│   ├── sc4s_dashboard.xml             # SC4S monitoring dashboard
│   └── sc4s_alerts.conf               # Alert definitions
└── docs/
    ├── deployment-guide.md            # Full deployment walkthrough
    ├── source-onboarding-playbook.md  # Step-by-step onboarding process
    ├── performance-tuning.md          # Tuning for high EPS
    ├── tls-configuration.md           # TLS/SSL setup guide
    └── troubleshooting.md             # Common issues and solutions
```

---

## Quick Start

### Prerequisites

- Docker Engine 20.10+ or Podman 3.0+
- Splunk Enterprise with HEC enabled
- Network access from SC4S host to Splunk HEC endpoint (port 8088)
- Syslog sources configured to send to SC4S host

### Step 1: Clone and Configure

```bash
git clone https://github.com/mrezwanulbari/splunk-sc4s.git
cd splunk-sc4s

# Copy environment template
cp .env.example .env

# Edit with your Splunk HEC details
vi .env
```

### Step 2: Set Environment Variables

```bash
# .env file
SC4S_DEST_SPLUNK_HEC_DEFAULT_URL=https://splunk-hec.company.com:8088
SC4S_DEST_SPLUNK_HEC_DEFAULT_TOKEN=your-hec-token-here
SC4S_DEST_SPLUNK_HEC_DEFAULT_TLS_VERIFY=no
```

### Step 3: Deploy SC4S

```bash
# Using Docker Compose
docker-compose up -d

# Verify SC4S is running
docker logs sc4s

# Test connectivity
echo "<134>1 2024-01-15T10:30:00Z testhost testapp - - - Test message" | nc -u localhost 514
```

---

## Source Onboarding

### Onboarding Workflow

```
1. Identify Source → 2. Check SC4S Support → 3. Configure Source
         ↓                                           ↓
4. Update splunk_metadata.csv → 5. Create Splunk Index → 6. Validate Data
```

### splunk_metadata.csv — Index Routing

```csv
# Template: key,metadata_field,metadata_value
# Route Palo Alto traffic logs to the firewall index
palo_alto_traffic,index,idx_firewall
palo_alto_threat,index,idx_firewall
palo_alto_system,index,idx_firewall

# Route Cisco ASA to network security index
cisco_asa,index,idx_network_security

# Route Linux syslog to OS index
nix_syslog,index,idx_os_linux

# Route VMware to infrastructure index
vmware_esx,index,idx_infrastructure
vmware_vcenter,index,idx_infrastructure
```

---

## Custom Log Paths

For sources not natively supported by SC4S, create custom log paths:

```conf
# custom-parsers/custom_app_parser.conf
# Custom parser for internal application logs

filter f_custom_myapp {
    program("myapp") or
    match("MYAPP" value("MESSAGE"));
};

log {
    source(s_DEFAULT);
    filter(f_custom_myapp);
    rewrite {
        set("custom_app" value(".splunk.sourcetype"));
        set("idx_custom" value(".splunk.index"));
        set("myapp" value(".splunk.source"));
    };
    destination(d_hec);
    flags(flow-control, final);
};
```

---

## Performance Tuning

| Parameter | Default | Recommended (High EPS) | Description |
|---|---|---|---|
| `SC4S_SOURCE_LISTEN_UDP_SOCKETS` | 1 | 4 | UDP listener threads |
| `SC4S_DEST_SPLUNK_HEC_WORKERS` | 10 | 20 | HEC connection workers |
| `SC4S_DEST_SPLUNK_HEC_MAX_BATCH_SIZE` | 500 | 1000 | Events per HEC batch |
| Docker `--cpus` | unlimited | 4 | CPU allocation |
| Docker `--memory` | unlimited | 8g | Memory allocation |

### Benchmark Results

| Configuration | EPS Capacity | Notes |
|---|---|---|
| Default (1 CPU, 2GB) | ~5,000 EPS | Suitable for small environments |
| Tuned (4 CPU, 8GB) | ~50,000 EPS | Production recommended |
| Multi-instance (2x tuned) | ~100,000 EPS | Behind load balancer |

---

## Troubleshooting

| Issue | Diagnosis | Solution |
|---|---|---|
| No data in Splunk | Check HEC connectivity | `curl -k https://splunk:8088/services/collector/health` |
| Wrong sourcetype | Source not classified | Add entry to `vendor_product_by_source.csv` |
| Data going to default index | Missing index mapping | Update `splunk_metadata.csv` |
| High container CPU | EPS exceeding capacity | Scale out or tune per Performance Tuning |
| TLS handshake failures | Certificate mismatch | Verify cert chain and CA bundle |

---

## Contributing

Contributions are welcome! See our contributing guidelines for details.

## License

This project is licensed under the MIT License.

---

> **Maintained by [Shakil Md. Rezwanul Bari](https://github.com/mrezwanulbari)** — Cybersecurity & SIEM Engineer focused on enterprise security operations and critical infrastructure protection.
