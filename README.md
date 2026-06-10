# Active Directory Replication Tools

PowerShell scripts for diagnosing and monitoring Active Directory replication health between domain controllers.

## 📋 Overview

Active Directory replication issues can cause authentication failures, Group Policy application delays, and inconsistent directory data across domain controllers. These tools provide comprehensive replication health checks to identify and troubleshoot replication problems.

## 📜 Scripts

### `Test-ADReplication.ps1`

Comprehensive AD replication health check that performs:

✅ Lists all domain controllers in the domain  
✅ Checks replication partners and their status  
✅ Identifies replication failures from Event Log  
✅ Verifies DNS resolution for all DCs  
✅ Checks time synchronization (critical for Kerberos)  
✅ Provides detailed analysis and recommendations  

## 🚀 Usage

### Basic Health Check
```powershell
.\Test-ADReplication.ps1
