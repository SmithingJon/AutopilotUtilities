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
function Update-WindowsAutpilotInfo {
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
        [Paramter()]
        [string]
        $DeploymentGroup,
        [Paramter()]
        [string]
        $RemoveFromGroup,
        [Parameter()]
        [ValidateLength(1,15)]
        [string]
        $AssignedComputerName,
        [Parameter()]
        [switch]
        $Assign,
        [Parameter()]
        [switch]
        $Reboot
    )
    #region If $assign, Check if device has an Autopilot Deployment Profile.
    if ($Assign) {
        $AssignmentStatus = (Get-AutopilotRecord).deploymentProfileAssignmentStatus
        if ($AssignmentStatus -contains ('assignedUnkownSyncState') -or ('updatingUnkownSyncState')) {
            $ProfileWait = $true
        } 
        else {
            $ProfileWait = $false
        }
    }
    #endregion
    #region Remove from all Deployment Groups except current Deployment Group
        
        Invoke-MSGraphRequest -Url "https://graph.microsoft.com/v1.0/groups/$($GroupId)/members/$($ObjectID)/$ref" -HttpMethod DELETE
        if ($ProfileWait) {
            
        }
    #endregion
    #region add to groups

    #endregion
}