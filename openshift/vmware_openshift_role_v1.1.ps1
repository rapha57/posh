<#
.SYNOPSIS
Script for creating a specific role used to install and configure the Openshift solution in a 
VMware vSphere environment.

.DESCRIPTION
The script will connect to one or more vCenter servers, create a role called "Openshift administrator" 
and set up a list of privileges needed to install and configure the solution, then disconnect.

.VERSION
2023-11-16 - 1.0 - Boulcourt.R - Initial dirty release, tested and functional. Should be eventually 
modified to add logging (TBD if needed).

2023-11-17 - 1.1 - Boulcourt.R - Refactored script for better modularity and error handling. 
Added explanatory comments for improved readability.
#>

# Init. variables
# ---------------
[Threading.Thread]::CurrentThread.CurrentCulture = 'en-US'
$ErrorActionPreference = "stop"

# Clear existing variables
Clear-Host
Remove-Variable -Name privileges -ErrorAction SilentlyContinue
Remove-Variable -Name vcenter* -ErrorAction SilentlyContinue

# Variables
# ---------
$vcenters = @("xxxx")
$vcenterCredentials = @{
    Username = 'xxxx@vsphere.local'
    Password = 'xxxx'
}

# Load Module
# -------------
Import-Module VMware.VimAutomation.Core -ErrorAction Stop

# Function to connect to vCenter
function Connect-ToVCenter {
    param (
        [string]$vcenter,
        [hashtable]$credentials
    )

    Connect-VIServer -Server $vcenter -User $credentials.Username -Password $credentials.Password -Force
}

# Function to create Openshift administrator role
function Create-OpenshiftAdministratorRole {
    param (
        [string]$vcenter
    )

    $privileges = @(
        'Cns.Searchable',
        'InventoryService.Tagging.AttachTag',
        'InventoryService.Tagging.CreateCategory',
        'InventoryService.Tagging.CreateTag',
        'InventoryService.Tagging.DeleteCategory',
        'InventoryService.Tagging.DeleteTag',
        'InventoryService.Tagging.EditCategory',
        'InventoryService.Tagging.EditTag',
        'Sessions.ValidateSession',
        'StorageProfile.Update',
        'StorageProfile.View',
        'Host.Config.Storage',
        'Resource.AssignVMToPool',
        'VApp.AssignResourcePool',
        'VApp.Import',
        'VirtualMachine.Config.AddNewDisk',
        'Datastore.AllocateSpace',
        'Datastore.Browse',
        'Datastore.FileManagement',
        'InventoryService.Tagging.ObjectAttachable',
        'Network.Assign',
        'VirtualMachine.Config.AddExistingDisk',
        'VirtualMachine.Config.AddRemoveDevice',
        'VirtualMachine.Config.AdvancedConfig',
        'VirtualMachine.Config.Annotation',
        'VirtualMachine.Config.CPUCount',
        'VirtualMachine.Config.DiskExtend',
        'VirtualMachine.Config.DiskLease',
        'VirtualMachine.Config.EditDevice',
        'VirtualMachine.Config.Memory',
        'VirtualMachine.Config.RemoveDisk',
        'VirtualMachine.Config.Rename',
        'VirtualMachine.Config.ResetGuestInfo',
        'VirtualMachine.Config.Resource',
        'VirtualMachine.Config.Settings',
        'VirtualMachine.Config.UpgradeVirtualHardware',
        'VirtualMachine.Interact.GuestControl',
        'VirtualMachine.Interact.PowerOff',
        'VirtualMachine.Interact.PowerOn',
        'VirtualMachine.Interact.Reset',
        'VirtualMachine.Inventory.Create',
        'VirtualMachine.Inventory.CreateFromExisting',
        'VirtualMachine.Inventory.Delete',
        'VirtualMachine.Provisioning.Clone',
        'VirtualMachine.Provisioning.MarkAsTemplate',
        'VirtualMachine.Provisioning.DeployTemplate',
        'Folder.Create',
        'Folder.Delete'
    )

    # Setup privileges based on the provided array
    New-VIRole -Name 'OpenShift administrator' -Privilege (Get-VIPrivilege -Id $privileges) | Out-Null
}

# Script sequence
# ---------------
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -DefaultVIServerMode Single -Scope Session -ParticipateInCeip:$false -Confirm:$false

foreach ($currentVcenter in $vcenters) {
    try {
        # Attempt to connect to vCenter
        Connect-ToVCenter -vcenter $currentVcenter -credentials $vcenterCredentials

        # Check if connection is successful before proceeding
        if ($?) {
            Create-OpenshiftAdministratorRole -vcenter $currentVcenter
        }
    }
    catch {
        Write-Host ("Error connecting to vCenter {0}: {1}" -f $currentVcenter, $_.Exception.Message)
        # Log error if needed
    }

    finally {
        # Disconnect from the vCenter Server
        Disconnect-VIServer $currentVcenter -Force -Confirm:$false
    }
}
