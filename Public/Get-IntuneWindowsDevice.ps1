function Get-IntuneWindowsDevice {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $serial = (Get-WmiObject -Class "WIN32_BIOS" -Property serialNumber).serialNumber
    )
    Test-MSGraph
    $results = Get-DeviceManagement_ManagedDevices | Where-Object serialNumber -Contains "$serial"
    $results
}