function Test-IntuneEnrollment{
    Test-MSGraph
    $serial = (Get-WmiObject -Class "WIN32_BIOS" -Property serialNumber).serialNumber
    $device = Get-DeviceManagement_ManagedDevices | Where-Object serialNumber -Contains "$serial"
    if ($device) {
        $true
    }
    else {
        $false
    }
}
