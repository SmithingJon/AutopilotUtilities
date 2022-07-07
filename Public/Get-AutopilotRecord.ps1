function Get-AutopilotRecord {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $serial = (Get-WmiObject -Class "WIN32_BIOS" -Property serialNumber).serialNumber
    )
    Test-MSGraph
    $URI = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities?`$filter=contains(serialNumber,'$($serial)')"
    $autopilotrecord = (Invoke-MSGraphRequest -Url $uri -HttpMethod GET -ErrorAction Stop).Value
    $autopilotrecord
}