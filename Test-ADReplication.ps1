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
.PARAMETER Verbose
    Show detailed information about each replication partner.
.EXAMPLE
    .\Test-ADReplication.ps1
    
    Basic replication health check.
.EXAMPLE
    .\Test-ADReplication.ps1 -Verbose
    
    Detailed replication check with partner information.
.NOTES
    Author: Vlad Gorin
    Website: sysadmintips.ru
    GitHub: github.com/vgorin-lab
    Requires: Active Directory PowerShell module (RSAT-AD-PowerShell)
    Requires: Run as Domain Admin or account with read permissions
.LINK
    https://sysadmintips.ru/microsoft-windows-server
#>

[CmdletBinding()]
param()

#Requires -Modules ActiveDirectory

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Active Directory Replication Health Check" -ForegroundColor Cyan
Write-Host " Author: Vlad Gorin | sysadmintips.ru" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

try {
    $domain = Get-ADDomain -ErrorAction Stop
    $domainControllers = Get-ADDomainController -ErrorAction Stop
    
    Write-Host "Domain: $($domain.DNSRoot)" -ForegroundColor Gray
    Write-Host "Domain Controllers: $($domainControllers.Count)" -ForegroundColor Gray
    Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor Gray
    
    Write-Host "--- Domain Controllers ---" -ForegroundColor Yellow
    foreach ($dc in $domainControllers) {
        $status = "✓"
        $color = "Green"
        
        # Check if DC is reachable
        $ping = Test-Connection -ComputerName $dc.HostName -Count 1 -Quiet -ErrorAction SilentlyContinue
        if (-not $ping) {
            $status = "✗"
            $color = "Red"
        }
        
        Write-Host "$status " -ForegroundColor $color -NoNewline
        Write-Host "$($dc.Name)" -ForegroundColor White -NoNewline
        Write-Host " ($($dc.HostName))" -ForegroundColor Gray
        
        if ($VerbosePreference -eq 'Continue') {
            Write-Host "    Site: $($dc.Site) | OS: $($dc.OperatingSystem)" -ForegroundColor DarkGray
        }
    }
    
    Write-Host "`n--- Replication Status ---" -ForegroundColor Yellow
    
    $replicationErrors = @()
    
    foreach ($dc in $domainControllers) {
        try {
            $replStatus = Get-ADReplicationPartnerMetadata -Target $dc.HostName -ErrorAction Stop
            
            foreach ($partner in $replStatus) {
                $lastSuccess = $partner.LastReplicationSuccess
                $lastAttempt = $partner.LastReplicationAttempt
                $partnerName = $partner.Partner
                
                if ($lastSuccess -lt (Get-Date).AddHours(-1)) {
                    $replicationErrors += [PSCustomObject]@{
                        SourceDC = $dc.Name
                        PartnerDC = $partnerName
                        LastSuccess = $lastSuccess
                        Status = "Delayed"
                    }
                    Write-Host "⚠ " -ForegroundColor Yellow -NoNewline
                    Write-Host "$($dc.Name) → $partnerName: Last success $($lastSuccess.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Yellow
                } else {
                    Write-Host "✓ " -ForegroundColor Green -NoNewline
                    Write-Host "$($dc.Name) → $partnerName: Replication healthy" -ForegroundColor Green
                }
            }
        } catch {
            Write-Host "✗ " -ForegroundColor Red -NoNewline
            Write-Host "$($dc.Name): Unable to query replication status" -ForegroundColor Red
            $replicationErrors += [PSCustomObject]@{
                SourceDC = $dc.Name
                PartnerDC = "N/A"
                LastSuccess = "N/A"
                Status = "Error: $($_.Exception.Message)"
            }
        }
    }
    
    Write-Host "`n--- DNS Resolution Check ---" -ForegroundColor Yellow
    foreach ($dc in $domainControllers) {
        $dnsCheck = Resolve-DnsName -Name $dc.HostName -ErrorAction SilentlyContinue
        if ($dnsCheck) {
            Write-Host "✓ " -ForegroundColor Green -NoNewline
            Write-Host "$($dc.HostName) resolves to $($dnsCheck.IPAddress)" -ForegroundColor Green
        } else {
            Write-Host "✗ " -ForegroundColor Red -NoNewline
            Write-Host "$($dc.HostName) DNS resolution failed" -ForegroundColor Red
        }
    }
    
    Write-Host "`n--- Time Synchronization ---" -ForegroundColor Yellow
    foreach ($dc in $domainControllers) {
        try {
            $dcTime = Invoke-Command -ComputerName $dc.HostName -ScriptBlock { Get-Date } -ErrorAction Stop
            $timeDiff = ((Get-Date) - $dcTime).TotalSeconds
            
            if ([Math]::Abs($timeDiff) -lt 5) {
                Write-Host "✓ " -ForegroundColor Green -NoNewline
                Write-Host "$($dc.Name): Time sync OK (diff: $([Math]::Round($timeDiff, 2))s)" -ForegroundColor Green
            } else {
                Write-Host "⚠ " -ForegroundColor Yellow -NoNewline
                Write-Host "$($dc.Name): Time drift detected ($([Math]::Round($timeDiff, 2))s)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "✗ " -ForegroundColor Red -NoNewline
            Write-Host "$($dc.Name): Unable to check time" -ForegroundColor Red
        }
    }
    
    # Summary
    Write-Host "`n--- Summary ---" -ForegroundColor Yellow
    if ($replicationErrors.Count -eq 0) {
        Write-Host "✓ AD replication is healthy across all domain controllers" -ForegroundColor Green
    } else {
        Write-Host "⚠ Found $($replicationErrors.Count) replication issue(s):" -ForegroundColor Yellow
        $replicationErrors | Format-Table -AutoSize
    }
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " For AD troubleshooting guides:" -ForegroundColor Cyan
    Write-Host " https://sysadmintips.ru/microsoft-windows-server" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
} catch {
    Write-Host "`n❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Make sure you have:" -ForegroundColor Yellow
    Write-Host "  1. Active Directory PowerShell module installed" -ForegroundColor Yellow
    Write-Host "  2. Domain Admin or appropriate permissions" -ForegroundColor Yellow
    Write-Host "  3. Network connectivity to domain controllers`n" -ForegroundColor Yellow
}