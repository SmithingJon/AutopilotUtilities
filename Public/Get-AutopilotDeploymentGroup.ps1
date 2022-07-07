function Get-AutopilotDeploymentGroup {
    param (
        [string]$SerialNumber = (Get-WmiObject -Class "WIN32_BIOS" -Property serialNumber).serialNumber
    )
    $autopilotrecord = Get-AutopilotDevice | Where-Object serialNumber -eq "$serialNumber"
    $autopilotrecord
    $profiles = Invoke-MSGraphRequest -url "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeploymentProfiles/"
    $profiles.value
}