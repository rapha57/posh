<#
.SYNOPSIS
    Duplicates permissions for a specified group from one vCenter to another.

.DESCRIPTION
    This script connects to a source vCenter, extracts permissions for a given group,
    then connects to a target vCenter and applies the same permissions, assuming the
    group already exists on the target with the same name.

.NOTES
    File Name      : Duplicate-GroupPermissions.ps1
    Author         : RBTADM
    Prerequisite   : PowerCLI 6.5 or later, VMware vSphere 6.5 or later
    Creation Date  : 2024-09-24
    Revision       : 1.1
#>

# Parameters
$sourceVCServer = "vcenter-source.domain.com"
$destVCServer = "vcenter-destination.domain.com"
$groupName = "GROUP_NAME"

# Function to handle errors
function Write-ErrorLog {
    param (
        [string]$ErrorMessage
    )
    Write-Host "ERROR: $ErrorMessage" -ForegroundColor Red
    # You can add additional error logging here if needed
}

try {
    # Connect to source vCenter
    Write-Host "Connecting to source vCenter: $sourceVCServer"
    Connect-VIServer -Server $sourceVCServer -ErrorAction Stop

    # Get permissions for the source group
    Write-Host "Retrieving permissions for group: $groupName"
    $sourcePerms = Get-VIPermission -ErrorAction Stop | Where-Object {$_.Principal -eq $groupName}
    
    if ($sourcePerms.Count -eq 0) {
        throw "No permissions found for group $groupName on source vCenter."
    }

    # Disconnect from source vCenter
    Disconnect-VIServer -Server $sourceVCServer -Confirm:$false

    # Connect to destination vCenter
    Write-Host "Connecting to destination vCenter: $destVCServer"
    Connect-VIServer -Server $destVCServer -ErrorAction Stop

    # Check if the group exists on the destination vCenter
    $destGroup = Get-VIAccount -Group -ErrorAction Stop | Where-Object {$_.Name -eq $groupName}
    if (-not $destGroup) {
        throw "Group $groupName does not exist on the destination vCenter. Please create it manually before running this script."
    }

    # Duplicate permissions
    $successCount = 0
    $failCount = 0
    foreach ($perm in $sourcePerms) {
        try {
            $entity = Get-Inventory -Name $perm.Entity.Name -ErrorAction Stop
            if ($entity) {
                New-VIPermission -Entity $entity -Principal $groupName -Role $perm.Role -Propagate $perm.Propagate -ErrorAction Stop
                Write-Host "Permission added for $groupName on $($entity.Name) with role $($perm.Role)" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host "Entity $($perm.Entity.Name) not found on destination vCenter. Permission skipped." -ForegroundColor Yellow
                $failCount++
            }
        } catch {
            Write-ErrorLog "Failed to add permission for $groupName on $($perm.Entity.Name): $_"
            $failCount++
        }
    }

    Write-Host "Permission duplication completed. Successful: $successCount, Failed: $failCount"
} catch {
    Write-ErrorLog "An error occurred: $_"
} finally {
    # Ensure we always disconnect from vCenter servers
    Get-VIServer | Disconnect-VIServer -Confirm:$false
}
