function Get-IntuneWindowsDevice {
    $serial = (Get-WmiObject -Class "WIN32_BIOS" -Property serialNumber).serialNumber
    $results = Get-DeviceManagement_ManagedDevices | Where-Object serialNumber -Contains "$serial"
    $results
}