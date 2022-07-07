<#
.SYNOPSIS
Gets the transitive AAD group membership of an Intune managed device

.DESCRIPTION
Long description

.PARAMETER DeviceName
The name of the device.

.PARAMETER DeviceSerial
The serial number of the device.

.PARAMETER AADDeviceId
The Azure Active Directory Device ID, NOT the Object ID or Intune Device ID.

.EXAMPLE
$GroupMembership = Get-DeviceGroupMembership -ComputerName "PC001" 
$GroupMembership = Get-DeviceGroupMembership -AADDeviceId "c089201c-ad84-1234-5678-00d06dc86d8f"
$GroupMembership | Sort Name | Out-GridView
# Is device a member of a specific group
$GroupMembership.Name -contains "Intune - All Windows 10 Workstations"

.NOTES
Requires the Microsoft.Graph.Intune module
#>
function Get-ManagedDeviceGroupMembership{
    [CmdletBinding(DefaultParameterSetName='Name')]
    Param(  
    [Parameter(Mandatory=$true,ParameterSetName='Name')]  
    [ValidateNotNullOrEmpty()]  
        [string]$DeviceName,
    [Parameter(Mandatory=$true,ParameterSetName='Serial')]
    [ValidateNotNullOrEmpty()]
        [string]$DeviceSerial,
    [Parameter(Mandatory=$true,ParameterSetName='Id')]  
    [ValidateNotNullOrEmpty()] 
        [string]$AADDeviceId
    )

    $ProgressPreference = 'SilentlyContinue'
    # Get a user token for MS Graph
    $GraphToken = Connect-MSGraph -PassThru

    # Find the object id
    If ($DeviceName)
    {
        $URL = "https://graph.microsoft.com/v1.0/devices?`$filter=displayName eq '$DeviceName'&`$select=id"
    }
    If ($DeviceSerial)
    {   
        $encoded = [uri]::EscapeDataString($DeviceSerial)
        $SerialURL = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities?`$filter=contains(serialNumber,'$encoded')"
        $headers = @{'Authorization'="Bearer " + $GraphToken}
        $D_Response = Invoke-WebRequest -Uri $SerialURL -Method GET -Headers $Headers -UseBasicParsing
        $test = ($D_Response.Content | ConvertFrom-Json).Value.azureADDeviceId
        if (!($test))
        {
            Write-Warning "Device not found!"
            Return
        }
        $AADDeviceId = ($D_Response.Content | ConvertFrom-Json).Value.azureADDeviceId
        $URL = "https://graph.microsoft.com/v1.0/devices?`$filter=deviceId eq '$AADDeviceID'&`$select=id"
    }
    If ($AADDeviceId)
    {
        $URL = "https://graph.microsoft.com/v1.0/devices?`$filter=deviceId eq '$AADDeviceID'&`$select=id"
    }
    $headers = @{'Authorization'="Bearer " + $GraphToken}
    $D_Response = Invoke-WebRequest -Uri $URL -Method GET -Headers $Headers -UseBasicParsing
    If ($D_Response.StatusCode -eq 200)
    {
        # Check for duplicates
        $DeviceId = ($D_Response.Content | ConvertFrom-Json).Value.id
        If ($DeviceId.Count -gt 1)
        {
            Write-Warning "Multiple devices found. Please pass a unique devicename or AAD device Id!"
            Return
        }
        else 
        {
            If ($DeviceId)
            {
                # Get the group membership
                $URL = "https://graph.microsoft.com/beta/devices/$DeviceId/memberOf?`$select=displayName,description,id,groupTypes,membershipRule,membershipRuleProcessingState"
                $G_Response = Invoke-WebRequest -Uri $URL -Method GET -Headers $Headers -UseBasicParsing
                If ($G_Response.StatusCode -eq 200)
                {
                    $Groups = ($G_Response.Content | ConvertFrom-Json).Value 
                }

                # Get the transitive group membership
                $URL = "https://graph.microsoft.com/beta/devices/$DeviceId/transitiveMemberOf?`$select=displayName,description,id,groupTypes,membershipRule,membershipRuleProcessingState"
                $TG_Response = Invoke-WebRequest -Uri $URL -Method GET -Headers $Headers -UseBasicParsing
                If ($TG_Response.StatusCode -eq 200)
                {
                    $TransitiveGroups = ($TG_Response.Content | ConvertFrom-Json).Value 
                }
            }
            else 
            {
                Write-Warning "Device not found!"    
            }
        }
    }
    else 
    {
        Return    
    }

    # If results found
    If ($Groups.Count -ge 1 -or $TransitiveGroups.Count -ge 1)
    {
        # Create a datatable to hold the groups
        $DataTable = [System.Data.DataTable]::New()
        $Columns = @()
        @(
            'Name'
            'Description'
            'Object Id'
            'Membership Type'
            'Direct or Transitive'
            'Membership Rule'
            'Membership Rule Processing State'
        ) | ForEach-Object {
            $Columns += [System.Data.DataColumn]::new("$_")
        }
        $DataTable.Columns.AddRange($Columns)

        # Add the groups
        foreach ($Group in $Groups)
        {
            If (($Group.groupTypes | Select-Object -First 1) -eq "DynamicMembership")
            {$MembershipType = "Dynamic"}
            Else {$MembershipType = "Assigned"}
            [void]$DataTable.Rows.Add($Group.displayName,$Group.description,$Group.id,$MembershipType,"Direct",$Group.membershipRule,$Group.membershipRuleProcessingState)
        }

        # Add the transitive groups
        foreach ($TransitiveGroup in ($TransitiveGroups | Where-Object {$_.id -NotIn $Groups.id}))
        {
            If (($TransitiveGroup.groupTypes | Select-Object -First 1) -eq "DynamicMembership")
            {$MembershipType = "Dynamic"}
            Else {$MembershipType = "Assigned"}
            [void]$DataTable.Rows.Add($TransitiveGroup.displayName,$TransitiveGroup.description,$TransitiveGroup.id,$MembershipType,"Transitive",$TransitiveGroup.membershipRule,$TransitiveGroup.membershipRuleProcessingState)
        }

        Return $DataTable
    }
}