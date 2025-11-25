<#
.SYNOPSIS
    Creates Microsoft Intune Enrollment service principal for Conditional Access exclusion
.DESCRIPTION
    This script creates the Microsoft Intune Enrollment service principal:
    - Microsoft Intune Enrollment (d4ebce55-015a-49b5-a083-c84d1797ae8c)
.NOTES
    Requires: Microsoft.Graph.Applications module
    Required Permissions: Application.ReadWrite.All
#>

#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Applications

# Connect to Microsoft Graph
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "Application.ReadWrite.All" -NoWelcome

# Define service principal
$servicePrincipals = @(
    @{
        DisplayName = "Microsoft Intune Enrollment"
        AppId = "d4ebce55-015a-49b5-a083-c84d1797ae8c"
    }
)

# Create each service principal
foreach ($sp in $servicePrincipals) {
    Write-Host "`nProcessing: $($sp.DisplayName) ($($sp.AppId))" -ForegroundColor Yellow
    
    try {
        # Check if service principal already exists
        $existing = Get-MgServicePrincipal -Filter "appId eq '$($sp.AppId)'" -ErrorAction SilentlyContinue
        
        if ($existing) {
            Write-Host "  ✓ Service principal already exists" -ForegroundColor Green
            Write-Host "    Object ID: $($existing.Id)" -ForegroundColor Gray
            Write-Host "    Display Name: $($existing.DisplayName)" -ForegroundColor Gray
        }
        else {
            # Create the service principal
            $newSP = New-MgServicePrincipal -AppId $sp.AppId -ErrorAction Stop
            Write-Host "  ✓ Service principal created successfully" -ForegroundColor Green
            Write-Host "    Object ID: $($newSP.Id)" -ForegroundColor Gray
            Write-Host "    Display Name: $($newSP.DisplayName)" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "  ✗ Failed to create service principal: $_" -ForegroundColor Red
    }
}

Write-Host "`n" -NoNewline
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "Service principals are now available for Conditional Access exclusion." -ForegroundColor White

# Disconnect
Disconnect-MgGraph | Out-Null
Write-Host "`nDisconnected from Microsoft Graph" -ForegroundColor Gray
