<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER __error__
Parameter description

.EXAMPLE
An example

.NOTES
Requres Microsoft.Graph.Intune module.
#>
function Update-WindowsAutopilotInfo {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $GroupTag,
        [Parameter()]
        [string]
        $AssignedUser,
        [Parameter()]
        [switch]
        $Online,
        [Parameter()]
        [string]
        $DeploymentGroup,
        [Parameter()]
        [string]
        $RemovalGroups,
        [Parameter()]
        [ValidateLength(0,15)]
        [string]
        $AssignedComputerName,
        [Parameter()]
        [switch]
        $Assign,
        [Parameter()]
        [switch]
        $Reboot
    )
    Test-MSGraph
    $id = (Test-MSGraph -output).id
    Write-Verbose "Connecting to AzureAD"
    Connect-AzureAD -TenantId $id | Out-Null
    $serialnumber = (Get-WmiObject -Class "WIN32_BIOS" -Property serialNumber).serialNumber
    #region If $assign, Check if device has an Autopilot Deployment Profile.
    if ($Assign) {
        $AssignmentStatus = (Get-AutopilotRecord).deploymentProfileAssignmentStatus
        if ($AssignmentStatus -contains ('assignedUnkownSyncState') -or ('pending')) {
            $Assign = $true
        } 
        else {
            $Assign = $false
        }
    }
    #endregion
    #region Remove from all Deployment Groups except current Deployment Group
    if ($RemovalGroups) {
        $RemovalGroups | Foreach-Object {
            $GroupName = $_
            Write-Verbose -Verbose "GroupName: '$GroupName'" 
            $GroupId = (Get-AADGroup -Filter "displayname eq '$GroupName'").id
            Write-Verbose "GroupId: '$GroupId'"
            $AzureAdDeviceId = (Get-AutoPilotDevice -serial $serialnumber).azureAdDeviceId
            Write-Verbose "AzureAdDeviceId: $AzureAdDeviceId"
            $ObjectID = (Get-AzureADDevice -Filter "deviceId eq guid'$AzureAdDeviceId'").ObjectId
            Write-Verbose "AzureAdObjectId: '$ObjectID'"
            Write-Warning "Removing $((Get-AutoPilotDevice -serial $serialnumber).displayname) from Group '$GroupName'."
            Remove-AzureADGroupMember -ObjectId $GroupId -MemberId $ObjectID
        }
        if ($Assign) {
            
        }
    }    
    #endregion
    #region add to groups

    #endregion
}