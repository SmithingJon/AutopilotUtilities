function Get-AutopilotRecord {
    [CmdletBinding()]
    param (
    )
    Test-MSGraph
    $serial = (Get-WmiObject -Class "WIN32_BIOS" -Property serialNumber).serialNumber
    $autopilotrecord = Get-AutopilotDevice | Where-Object serialNumber -eq "$serial"
    $autopilotrecord
}