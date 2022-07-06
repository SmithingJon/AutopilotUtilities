function Get-AutopilotRecord {
    $serial = (Get-WmiObject -Class "WIN32_BIOS" -Property serialNumber).serialNumber
    $autopilotrecord = Get-AutopilotDevice | Where serialNumber -eq "$serial"
    $autopilotrecord
}