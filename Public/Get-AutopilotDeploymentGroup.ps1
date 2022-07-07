function Get-AutopilotDeploymentGroup {
    [CmdletBinding()]
    param (
        [string]$SerialNumber = (Get-WmiObject -Class "WIN32_BIOS" -Property serialNumber).serialNumber
    )
    Test-MSGraph
    $autopilotrecord = Get-AutopilotDevice | Where-Object serialNumber -eq "$serialNumber"
    $autopilotrecord
    $profiles = Invoke-MSGraphRequest -url "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles/"
    $profiles.value
}