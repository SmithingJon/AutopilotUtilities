function Test-AutopilotRecord {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $serial = (Get-WmiObject -Class "WIN32_BIOS" -Property serialNumber).serialNumber
    )
    Test-MSGraph
    Write-Verbose "Looking for Autopilot record with Serial $serial"
    $URI = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities?`$filter=contains(serialNumber,'$($serial)')"
    $Device = Invoke-MSGraphRequest -Url $uri -HttpMethod GET -ErrorAction Stop
    if ($Device) {
        $true
    }
    else {
        $false
    }
}