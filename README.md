# 🔄 AD Replication Tools

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell Version](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)

PowerShell script for diagnosing, auditing, and monitoring Active Directory replication health across domain controllers.

It helps quickly detect replication failures, latency issues, DNS misconfiguration, and time synchronization problems in AD environments.

---

## 🏷️ Keywords

Active Directory Replication, AD Replication Monitoring, PowerShell AD Replication, Repadmin alternative, DCDiag replication check, Domain Controller replication status, Get-ADReplicationPartnerMetadata, AD health check, replication failure detection, SYSVOL replication, DFSR status, Kerberos time sync, AD troubleshooting, Windows Server AD tools

---

## 📖 Table of Contents

* [Features](#features)
* [Prerequisites](#prerequisites)
* [Installation](#installation)
* [Quick Start](#quick-start)
* [Examples](#examples)
* [Output](#output)
* [Documentation](#documentation)
* [License](#license)
* [Author](#author)

---

## ✨ Features

* Lists all domain controllers in the domain
* Checks replication partners and their status
* Detects replication failures from directory metadata
* Validates DNS resolution for all domain controllers
* Checks time synchronization (Kerberos consistency)
* Returns structured PowerShell objects for automation

---

## ⚙️ Prerequisites

* Windows PowerShell 5.1 or PowerShell 7+
* Active Directory PowerShell module (RSAT-AD-Tools)
* Domain user account with read permissions

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

Run replication health check for current domain:

```powershell
.\Test-ADReplication.ps1
```

---

## 📚 Examples

### Check specific domain

```powershell
.\Test-ADReplication.ps1 -Domain corp.contoso.com
```

### Verbose troubleshooting mode

```powershell
.\Test-ADReplication.ps1 -Verbose
```

### Save output for automation

```powershell
$health = .\Test-ADReplication.ps1
$health.OverallHealth
$health.ReplicationErrors
```

---

## 📊 Output

Example output:

```text
=== AD Replication Health Check ===

Domain              : contoso.com
DC Count            : 4
Healthy Replication : True
Failed Partners     : 0
Latency Issues      : None
DNS Status          : OK
Time Sync Status    : OK
```

---

## 🔗 Documentation

* AD replication troubleshooting concepts (Microsoft AD DS replication model)
* Uses native AD PowerShell cmdlets like `Get-ADReplicationPartnerMetadata`
* Inspired by traditional `repadmin` and `dcdiag` diagnostics

More sysadmin tips and tools:
https://sysadmintips.ru

---

## 📄 License

Distributed under the MIT License. See LICENSE file for details.

---

## 👤 Author

**Vlad Gorin** (vgorin-lab)
