function Test-IntuneEnrollment{
    $ProgressPreference = 'SilentlyContinue'
    # Get a user token for MS Graph
    $GraphToken = Connect-MSGraph -PassThru
    $serial = (Get-WmiObject -Class "WIN32_BIOS" -Property serialNumber).serialNumber
    $SerialURL = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=serialNumber eq '$serial'&`$select=azureADDeviceId"
    $headers = @{'Authorization'="Bearer " + $GraphToken}
    $D_Response = Invoke-WebRequest -Uri $SerialURL -Method GET -Headers $Headers -UseBasicParsing
    $test = ($D_Response.Content | ConvertFrom-Json).Value.azureADDeviceId
    if ($device) {
        $true
    }
    else {
        $false
    }
}
