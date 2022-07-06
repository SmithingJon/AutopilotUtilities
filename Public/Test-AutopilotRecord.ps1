function Test-AutopilotRecord {
    $serial = (Get-WmiObject -Class "WIN32_BIOS" -Property serialNumber).serialNumber
    $URI = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities?`$filter=contains(serialNumber,'$($serial)')"
    $Device = Invoke-MSGraphRequest -Url $uri -HttpMethod GET -ErrorAction Stop
    if ($Device) {
        $true
    }
    else {
        $false
    }
}