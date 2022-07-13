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
    function Wait-AutopilotAssign {
        [CmdletBinding()]
        param (
            [Parameter()]
            [switch]
            $unassign
        )
        if ($unassign){
			$assignStart = Get-Date
			$processingCount = 1
			while ($processingCount -gt 0)
			{
				$processingCount = 0
				$autopilotDevices | % {
					$device = Get-AutopilotDevice -id $_.id -Expand
					if (-not ($device.deploymentProfileAssignmentStatus.StartsWith("notAssigned"))) {
						$processingCount = $processingCount + 1
					}
				}
				$deviceCount = $autopilotDevices.Length
				Write-Host "Waiting for $processingCount of $deviceCount to be unassigned"
				if ($processingCount -gt 0){
					Start-Sleep 30
				}	
			}
			$assignDuration = (Get-Date) - $assignStart
			$assignSeconds = [Math]::Ceiling($assignDuration.TotalSeconds)
			Write-Host "Profile Unassigned from device.  Elapsed time to complete unassignment: $assignSeconds seconds"	
		}
        else {
			$assignStart = Get-Date
			$processingCount = 1
			while ($processingCount -gt 0)
			{
				$processingCount = 0
				$autopilotDevices | % {
					$device = Get-AutopilotDevice -id $_.id -Expand
					if (-not ($device.deploymentProfileAssignmentStatus.StartsWith("assigned"))) {
						$processingCount = $processingCount + 1
					}
				}
				$deviceCount = $autopilotDevices.Length
				Write-Host "Waiting for $processingCount of $deviceCount to be assigned"
				if ($processingCount -gt 0){
					Start-Sleep 30
				}	
			}
			$assignDuration = (Get-Date) - $assignStart
			$assignSeconds = [Math]::Ceiling($assignDuration.TotalSeconds)
			Write-Host "Profiles assigned to device.  Elapsed time to complete assignment: $assignSeconds seconds"	
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
            Write-Warning "Removing Device with Serial $((Get-AutoPilotDevice -serial $serialnumber).serialNumber) from Group '$GroupName'."
            Remove-AzureADGroupMember -ObjectId $GroupId -MemberId $ObjectID
        }
        if ($Assign) {
            Wait-AutopilotAssign -unassign
        }
    }    
    #endregion
    #region add to groups
    if ($DeploymentGroup) {
        $GroupName = $DeploymentGroup
        Write-Verbose -Verbose "GroupName: '$GroupName'" 
        $GroupId = (Get-AADGroup -Filter "displayname eq '$GroupName'").id
        Write-Verbose "GroupId: '$GroupId'"
        $AzureAdDeviceId = (Get-AutoPilotDevice -serial $serialnumber).azureAdDeviceId
        Write-Verbose "AzureAdDeviceId: $AzureAdDeviceId"
        $ObjectID = (Get-AzureADDevice -Filter "deviceId eq guid'$AzureAdDeviceId'").ObjectId
        Write-Verbose "AzureAdObjectId: '$ObjectID'"
        Write-Warning "Adding Device with Serial $((Get-AutoPilotDevice -serial $serialnumber).serialNumber) to Group '$GroupName'."
        Add-AzureADGroupMember -ObjectId $GroupId -MemberId $ObjectID
    }
    if ($Assign) {
        Wait-AutopilotAssign
    }
    #endregion
    #region Update GroupTag
    if ($GroupTag) {
        $AutopilotID = (Get-AutoPilotDevice -serial $serialnumber).id
        Write-Warning "Setting GroupTag for Device with Serial $((Get-AutoPilotDevice -serial $serialnumber).serialNumber) to '$GroupTag'"
        Set-AutopilotDevice -id $AutopilotID -groupTag $GroupTag
    }
    if ($Assign) {
        Wait-AutopilotAssign
    }
    #endregion
    #region Update AssignedComputerName
    if ($AssignedComputerName) {
        $AutopilotID = (Get-AutoPilotDevice -serial $serialnumber).id
        Write-Warning "Setting AssignedComputername for Device with Serial $((Get-AutoPilotDevice -serial $serialnumber).serialNumber) to '$AssignedComputername'"
        Set-AutopilotDevice -id $AutopilotID -displayName $AssignedComputerName
    }
    #endregion
    if ($Reboot) {
        Write-Warning Restart-Computer
        Restart-Computer -Force
    }
}