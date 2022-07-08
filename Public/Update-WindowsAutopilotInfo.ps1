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
    Connect-AzureAD -TenantId $id
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
        Foreach-Object $GroupName in $RemovalGroups { 
            $GroupId = Get-AADGroup -Filter "displayname eq '$GroupName'"
            $AzureAdDeviceId = (Get-AutoPilotDevice -serial $serialnumber).azureAdDeviceId
            $ObjectID = (Get-AzureADDevice -SearchString "$AzureAdDeviceId").ObjectId
            Write-Warning "Removing $((Get-AutoPilotDevice -serial $serialnumber).displayname) from Group $GroupName."
            Invoke-MSGraphRequest -Url "https://graph.microsoft.com/v1.0/groups/$($GroupId)/members/$($ObjectID)/$ref" -HttpMethod DELETE
        }
        if ($ProfileWait) {
            
        }
    }    
    #endregion
    #region add to groups

    #endregion
}