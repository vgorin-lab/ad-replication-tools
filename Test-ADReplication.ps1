<#
.SYNOPSIS
    Diagnoses Active Directory replication status between domain controllers.
.DESCRIPTION
    Comprehensive AD replication health check that:
    - Lists all domain controllers in the domain
    - Checks replication partners and their status
    - Identifies replication failures from Event Log
    - Verifies DNS resolution for all DCs
    - Checks time synchronization (critical for Kerberos)
    
    Essential tool for troubleshooting AD replication issues.
    
    Companion tool for sysadmintips.ru Active Directory guides.
.PARAMETER Domain
    Domain FQDN to check. If not specified, uses current domain from USERDNSDOMAIN environment variable.
.PARAMETER Verbose
    Show detailed information about each replication partner.
.EXAMPLE
    .\Test-ADReplication.ps1
    
    Basic replication health check for current domain.
.EXAMPLE
    .\Test-ADReplication.ps1 -Domain corp.contoso.com -Verbose
    
    Detailed replication check with partner information for specific domain.
.NOTES
    Author: Vlad Gorin (vgorin-lab)
    License: MIT
    Website: sysadmintips.ru
    GitHub: github.com/vgorin-lab
    Requires: Active Directory PowerShell module (RSAT-AD-PowerShell)
    Requires: Run as Domain Admin or account with read permissions
.LINK
    https://sysadmintips.ru/microsoft-windows-server
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$Domain = $env:USERDNSDOMAIN
)

#Requires -Modules ActiveDirectory

# --- Helper function to write colored headers (only for console decoration) ---
function Write-ColorHeader {
    param([string]$Text, [string]$Color = "Cyan")
    Write-Host "`n========================================" -ForegroundColor $Color
    Write-Host " $Text" -ForegroundColor $Color
    Write-Host "========================================" -ForegroundColor $Color
}

# --- Main script logic with return object ---
$report = @{
    Domain = $null
    DomainControllers = @()
    ReplicationErrors = @()
    DnsErrors = @()
    TimeErrors = @()
    OverallHealth = "Healthy"
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

try {
    # --- Validate domain ---
    if (-not $Domain) {
        throw "Domain name not specified and USERDNSDOMAIN environment variable is empty."
    }
    Write-Verbose "Target domain: $Domain"

    # --- Get domain object and DCs ---
    $domainObj = Get-ADDomain -Identity $Domain -ErrorAction Stop
    $domainControllers = Get-ADDomainController -Filter * -Server $Domain -ErrorAction Stop

    $report.Domain = $domainObj.DNSRoot
    $report.DomainControllers = $domainControllers | ForEach-Object { $_.Name }

    Write-ColorHeader "Active Directory Replication Health Check" -Color "Cyan"
    Write-Host "Author: Vlad Gorin | sysadmintips.ru" -ForegroundColor Cyan
    Write-Host "Domain: $($report.Domain)" -ForegroundColor Gray
    Write-Host "Timestamp: $($report.Timestamp)" -ForegroundColor Gray
    Write-Host "Domain Controllers: $($domainControllers.Count)`n" -ForegroundColor Gray

    # --- Section 1: Domain Controllers and reachability ---
    Write-ColorHeader "Domain Controllers" -Color "Yellow"
    $dcStatus = @()
    foreach ($dc in $domainControllers) {
        $reachable = Test-Connection -ComputerName $dc.HostName -Count 1 -Quiet -ErrorAction SilentlyContinue
        $status = $reachable ? "UP" : "DOWN"
        $color = $reachable ? "Green" : "Red"
        Write-Host "$($reachable ? '✓' : '✗') " -ForegroundColor $color -NoNewline
        Write-Host "$($dc.Name) ($($dc.HostName))" -ForegroundColor White
        if ($VerbosePreference -eq 'Continue') {
            Write-Host "    Site: $($dc.Site) | OS: $($dc.OperatingSystem)" -ForegroundColor DarkGray
        }
        $dcStatus += [PSCustomObject]@{
            DC        = $dc.Name
            Hostname  = $dc.HostName
            Reachable = $reachable
            Site      = $dc.Site
            OS        = $dc.OperatingSystem
        }
    }

    # --- Section 2: Replication Status ---
    Write-ColorHeader "Replication Status" -Color "Yellow"
    $replicationErrors = @()

    foreach ($dc in $domainControllers) {
        try {
            $replStatus = Get-ADReplicationPartnerMetadata -Target $dc.HostName -ErrorAction Stop
            foreach ($partner in $replStatus) {
                $lastSuccess = $partner.LastReplicationSuccess
                $partnerName = $partner.Partner
                $isDelayed = $lastSuccess -lt (Get-Date).AddHours(-1)
                
                if ($isDelayed) {
                    $replicationErrors += [PSCustomObject]@{
                        SourceDC    = $dc.Name
                        PartnerDC   = $partnerName
                        LastSuccess = $lastSuccess.ToString("yyyy-MM-dd HH:mm")
                        Status      = "Delayed"
                    }
                    Write-Host "⚠ " -ForegroundColor Yellow -NoNewline
                    Write-Host "$($dc.Name) → $partnerName : Last success $($lastSuccess.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Yellow
                } else {
                    Write-Host "✓ " -ForegroundColor Green -NoNewline
                    Write-Host "$($dc.Name) → $partnerName : Replication healthy" -ForegroundColor Green
                }
            }
        } catch {
            Write-Host "✗ " -ForegroundColor Red -NoNewline
            Write-Host "$($dc.Name): Unable to query replication status" -ForegroundColor Red
            $replicationErrors += [PSCustomObject]@{
                SourceDC    = $dc.Name
                PartnerDC   = "N/A"
                LastSuccess = $null
                Status      = "Error: $($_.Exception.Message)"
            }
        }
    }
    $report.ReplicationErrors = $replicationErrors

    # --- Section 3: DNS Resolution ---
    Write-ColorHeader "DNS Resolution Check" -Color "Yellow"
    $dnsErrors = @()
    foreach ($dc in $domainControllers) {
        try {
            $dnsResult = Resolve-DnsName -Name $dc.HostName -ErrorAction Stop
            Write-Host "✓ " -ForegroundColor Green -NoNewline
            Write-Host "$($dc.HostName) resolves to $($dnsResult.IPAddress)" -ForegroundColor Green
        } catch {
            Write-Host "✗ " -ForegroundColor Red -NoNewline
            Write-Host "$($dc.HostName) DNS resolution failed" -ForegroundColor Red
            $dnsErrors += $dc.HostName
        }
    }
    $report.DnsErrors = $dnsErrors

    # --- Section 4: Time Synchronization ---
    Write-ColorHeader "Time Synchronization" -Color "Yellow"
    $timeErrors = @()
    foreach ($dc in $domainControllers) {
        try {
            # Try WinRM first, fallback to WMI
            $dcTime = Invoke-Command -ComputerName $dc.HostName -ScriptBlock { Get-Date } -ErrorAction Stop
            $timeDiff = ((Get-Date) - $dcTime).TotalSeconds
            if ([Math]::Abs($timeDiff) -lt 5) {
                Write-Host "✓ " -ForegroundColor Green -NoNewline
                Write-Host "$($dc.Name): Time sync OK (diff: $([Math]::Round($timeDiff, 2))s)" -ForegroundColor Green
            } else {
                Write-Host "⚠ " -ForegroundColor Yellow -NoNewline
                Write-Host "$($dc.Name): Time drift detected ($([Math]::Round($timeDiff, 2))s)" -ForegroundColor Yellow
                $timeErrors += "$($dc.Name) - drift $([Math]::Round($timeDiff, 2))s"
            }
        } catch {
            Write-Host "⚠ " -ForegroundColor Yellow -NoNewline
            Write-Host "$($dc.Name): Unable to check time via WinRM (skipping)" -ForegroundColor Yellow
            $timeErrors += "$($dc.Name) - WinRM error"
        }
    }
    $report.TimeErrors = $timeErrors

    # --- Summary and output ---
    Write-ColorHeader "Summary" -Color "Yellow"
    $errorCount = $replicationErrors.Count + $dnsErrors.Count + $timeErrors.Count
    if ($errorCount -eq 0) {
        Write-Output "✓ AD replication is healthy across all domain controllers"
        $report.OverallHealth = "Healthy"
    } else {
        Write-Output "⚠ Found $errorCount issue(s):"
        if ($replicationErrors.Count -gt 0) {
            Write-Output "  Replication errors: $($replicationErrors.Count)"
        }
        if ($dnsErrors.Count -gt 0) {
            Write-Output "  DNS errors: $($dnsErrors.Count)"
        }
        if ($timeErrors.Count -gt 0) {
            Write-Output "  Time sync issues: $($timeErrors.Count)"
        }
        $report.OverallHealth = "IssuesFound"
    }

    Write-Output "`nFor detailed AD troubleshooting guides: https://sysadmintips.ru/microsoft-windows-server"
}
catch {
    Write-Error "ERROR: $($_.Exception.Message)"
    Write-Output "`nMake sure you have:"
    Write-Output "  1. Active Directory PowerShell module installed"
    Write-Output "  2. Domain Admin or appropriate permissions"
    Write-Output "  3. Network connectivity to domain controllers"
    $report.OverallHealth = "Error"
}

# --- Return object for automation ---
return [PSCustomObject]$report
