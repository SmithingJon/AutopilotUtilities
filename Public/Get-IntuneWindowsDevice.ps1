Connect-MSGraph
Connect-MgGraph
Import-Module Microsoft.Graph.Intune
Import-Module Microsoft.Graph.Identity.DirectoryManagement
function Get-IntuneWindowsDeviceGroups {
    $serial = (Get-WmiObject -Class "WIN32_BIOS" -Property serialNumber).serialNumber
    $serial
    $device = Get-DeviceManagement_ManagedDevices | Where-Object serialNumber -Contains "$serial"
    $device.id
    $device.deviceName
    $device.model
    pause
    Get-MgDeviceMemberOf -DeviceId $device.id
}
Get-IntuneWindowsDevice