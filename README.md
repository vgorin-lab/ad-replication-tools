# AD Replication Tools

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell Version](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)

PowerShell script for diagnosing and monitoring Active Directory replication health between domain controllers.

## 🏷️ Keywords
AD Replication, Active Directory Health, Repadmin, PowerShell AD, DCDiag, Replication Status, Domain Controller Health, AD Topology, Get-ADReplicationPartnerMetadata

## ✨ Features
- Lists all domain controllers in the domain
- Checks replication partners and their status
- Identifies replication failures from Event Log
- Verifies DNS resolution for all DCs
- Checks time synchronization (critical for Kerberos)
- Returns a PowerShell object for automation

## ⚙️ Prerequisites
- Windows PowerShell 5.1 or PowerShell 7+
- Active Directory PowerShell module (RSAT-AD-PowerShell)
- Domain user account (authenticated)

## 🚀 Installation

### Option 1: Clone the repository
```powershell
git clone https://github.com/vgorin-lab/ad-replication-tools.git
cd ad-replication-tools
```

### Option 2: Download the script directly
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/vgorin-lab/ad-replication-tools/main/Test-ADReplication.ps1" -OutFile "Test-ADReplication.ps1"
```

## ⚡ Quick Start
Run a basic replication health check for current domain:
```powershell
.\Test-ADReplication.ps1
```

## 📚 Examples

### Check a specific domain
```powershell
.\Test-ADReplication.ps1 -Domain corp.contoso.com
```

### Run with verbose output  
```powershell
.\Test-ADReplication.ps1 -Verbose
```

### Save results to a variable for automation
```powershell
$health = .\Test-ADReplication.ps1
$health.OverallHealth
$health.ReplicationErrors
```

## 🔗 Documentation

More sysadmin tips and tricks: [sysadmintips.ru](https://sysadmintips.ru)
*Detailed AD replication guide coming soon.*

## 📄 License
Distributed under the MIT License. See LICENSE file for more information.

## Author
**Vlad Gorin** (vgorin-lab)


