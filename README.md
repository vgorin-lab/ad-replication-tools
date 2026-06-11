# 🔄 AD Replication Tools

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell Version](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)

PowerShell script for diagnosing, auditing, and monitoring Active Directory replication health across domain controllers.

The tool performs a multi-layer health check including replication status, DNS resolution, and time synchronization — essential for troubleshooting Active Directory issues and validating domain health.

---

## 🏷️ Keywords

Active Directory Replication, AD Replication Monitoring, PowerShell AD Replication, Repadmin alternative, DCDiag replacement, Domain Controller replication status, Get-ADReplicationPartnerMetadata, AD health check script, replication failure detection, SYSVOL replication, DFSR, Kerberos time sync, DNS resolution AD, Windows Server AD diagnostics

---

## 📖 Table of Contents

* [Features](#features)
* [Prerequisites](#prerequisites)
* [Installation](#installation)
* [Quick Start](#quick-start)
* [Examples](#examples)
* [Output](#output)
* [Object Model](#object-model)
* [Use Cases](#use-cases)
* [Documentation](#documentation)
* [License](#license)
* [Author](#author)

---

## ✨ Features

* Lists all domain controllers in the domain
* Checks replication partner health and status
* Detects replication delays and failures
* Validates DNS resolution for all DCs
* Checks time synchronization (Kerberos critical dependency)
* Provides structured PowerShell object output for automation
* Supports verbose troubleshooting mode

---

## ⚙️ Prerequisites

* Windows PowerShell 5.1 or PowerShell 7+
* Active Directory PowerShell module (RSAT-AD-PowerShell)
* Domain user account with read permissions
* Network connectivity to domain controllers
* (Optional) WinRM enabled for time synchronization checks

---

## 🚀 Installation

### Option 1: Clone repository

```powershell
git clone https://github.com/vgorin-lab/ad-replication-tools.git
cd ad-replication-tools
```

### Option 2: Download script directly

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/vgorin-lab/ad-replication-tools/main/Test-ADReplication.ps1" -OutFile "Test-ADReplication.ps1"
```

---

## ⚡ Quick Start

Run a basic Active Directory replication health check:

```powershell
.\Test-ADReplication.ps1
```

---

## 📚 Examples

### Check specific domain

```powershell
.\Test-ADReplication.ps1 -Domain corp.contoso.com
```

### Run with verbose output

```powershell
.\Test-ADReplication.ps1 -Verbose
```

### Save results for automation

```powershell
$health = .\Test-ADReplication.ps1
$health.OverallHealth
$health.ReplicationErrors
$health.DnsErrors
$health.TimeErrors
```

---

## 📊 Output

The script provides structured console output and machine-readable results.

### Example console output

```text
========================================
 Active Directory Replication Health Check
========================================
Domain: corp.contoso.com
Timestamp: 2026-06-11 17:40:00
Domain Controllers: 4
```

### Replication status

```text
✓ DC01 → DC02 : Replication healthy
⚠ DC02 → DC03 : Last success 2026-06-11 15:20
✗ DC03: Unable to query replication status
```

### DNS check

```text
✓ dc01.corp.contoso.com resolves to 10.0.0.1
✗ dc03.corp.contoso.com DNS resolution failed
```

### Time synchronization

```text
✓ DC01: Time sync OK (0.42s)
⚠ DC02: Time drift detected (6.31s)
```

---

## 🧩 Object Model

The script returns a PowerShell object for automation:

```powershell
$report = .\Test-ADReplication.ps1
$report | Format-List
```

### Core properties

```text
Domain
DomainControllers
ReplicationErrors
DnsErrors
TimeErrors
OverallHealth
Timestamp
```

---

### ReplicationErrors object

```text
SourceDC
PartnerDC
LastSuccess
Status
```

Example:

```text
SourceDC    : DC02
PartnerDC   : DC03
LastSuccess : 2026-06-11 15:20
Status      : Delayed
```

---

### OverallHealth states

```text
Healthy
IssuesFound
Error
```

---

## 🧠 Use Cases

* Active Directory replication troubleshooting
* Post-DC deployment validation
* Pre-migration health checks
* Monitoring AD infrastructure health
* Replacement for basic repadmin /replsummary workflows
* DNS and Kerberos validation in domain environments

---

## 🔗 Documentation

Built using native Microsoft Active Directory PowerShell cmdlets:

* Get-ADDomainController
* Get-ADReplicationPartnerMetadata
* Resolve-DnsName
* Invoke-Command (WinRM time validation)

More guides and sysadmin tools:
https://sysadmintips.ru

---

## 📄 License

Distributed under the MIT License. See LICENSE file for details.

---

## 👤 Author

**Vlad Gorin** (vgorin-lab)
