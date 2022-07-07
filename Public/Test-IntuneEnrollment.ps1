function Test-IntuneEnrollment{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $serial = (Get-WmiObject -Class "WIN32_BIOS" -Property serialNumber).serialNumber
    )
    Test-MSGraph
    Write-Verbose "Looking for Enrolled device with Serial $serial"
    $device = Get-DeviceManagement_ManagedDevices | Where-Object serialNumber -Contains "$serial"
    if ($device) {
        $true
    }
    else {
        $false
    }
}
