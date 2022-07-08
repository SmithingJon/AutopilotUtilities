<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.EXAMPLE
An example

.NOTES
General notes
#>
function Start-AutopilotUtilities {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string]$CustomProfile,

        [ValidateSet (
            'GroupTag',
            'DeploymentGroup',
            'AssignedUser',
            'AssignedComputerName',
            'PostAction',
            'Assign'
        )]
        [string[]]$Disabled,

        [ValidateSet (
            'GroupTag',
            'DeploymentGroup',
            'AssignedUser',
            'AssignedComputerName',
            'PostAction',
            'Assign',
            'Apply',
            'Run',
            'Docs'
        )]
        [string[]]$Hidden,

        [string]$DeploymentGroup,
        [string[]]$DeploymentGroupOptions,
        [switch]$Assign,
        [string]$AssignedUser,
        [string]$AssignedUserExample = 'someone@example.com',
        [string]$AssignedComputerName,
        [string]$AssignedComputerNameExample = 'Azure AD Join Only',
        [string]$GroupTag,
        [string[]]$GroupTagOptions,
        [switch]$deleteIntune,
        [switch]$deleteAutopilot,
        [switch]$deleteAzure,
        [ValidateSet (
            'Quit',
            'Restart',
            'Shutdown',
            'Sysprep',
            'SysprepReboot',
            'SysprepShutdown',
            'GeneralizeReboot',
            'GeneralizeShutdown'
        )]
        [string]$PostAction = 'Quit',
        [ValidateSet (
            'CommandPrompt',
            'PowerShell',
            'PowerShellISE',
            'WindowsExplorer',
            'WindowsSettings',
            'NetworkingWireless',
            'Restart',
            'Shutdown',
            'Sysprep',
            'SysprepReboot',
            'SysprepShutdown',
            'SysprepAudit',
            'EventViewer',
            'GetAutopilotDiagnostics',
            'GetAutopilotDiagnosticsOnline',
            'MDMDiag',
            'MDMDiagAutopilot',
            'MDMDiagAutopilotTPM'
        )]
        [string]$Run = 'PowerShell',
        [string]$Docs,
        [string]$Title = 'Autopilot Utilities'
    )

    #================================================
    #   WinPE and WinOS Start
    #================================================
    if ($env:SystemDrive -eq 'X:') {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Green "Start-AutopilotUtilities in WinPE"
        $ProgramDataOSDeploy = 'C:\ProgramData\OSDeploy'
        $JsonPath = "$ProgramDataOSDeploy\OSDeploy.AutopilotUtilities.json"
    }
    if ($env:SystemDrive -ne 'X:') {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Green "Start-AutopilotUtilities"
        $ProgramDataOSDeploy = "$env:ProgramData\OSDeploy"
        $JsonPath = "$ProgramDataOSDeploy\OSDeploy.AutopilotUtilities.json"
    }
    #================================================
    #   WinOS Transcript
    #================================================
    if ($env:SystemDrive -ne 'X:') {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Start-Transcript"
        $Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Start-AutopilotUtilities.log"
        Start-Transcript -Path (Join-Path "$env:SystemRoot\Temp" $Transcript) -ErrorAction Ignore
        $host.ui.RawUI.WindowTitle = "Start-AutopilotUtilities $env:SystemRoot\Temp\$Transcript"
    }
    #================================================
    #   WinOS Console Disable Line Wrap
    #================================================
    reg add HKCU\Console /v LineWrap /t REG_DWORD /d 0 /f
    #================================================
    #   Custom Profile Sample Variables
    #================================================
    if ($CustomProfile -eq 'Sample') {
        $Title = 'Sample Autopilot Registration'
        $DeploymentGroup = 'Administrators'
        $AssignedComputerName = 'OSD-' + ((Get-CimInstance -ClassName Win32_BIOS).SerialNumber).Trim()
        $PostAction = 'Shutdown'
        $Assign = $true
        $Run = 'PowerShell'
        $Docs = 'https://www.osdeploy.com/'
        $Hidden = 'GroupTag'
    }
    #================================================
    #   Custom Profile
    #================================================
    if ($CustomProfile) {
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Loading AutopilotUtilities Custom Profile $CustomProfile"

        $CustomProfileJson = Get-ChildItem "$($MyInvocation.MyCommand.Module.ModuleBase)\CustomProfile" *.json | Where-Object {$_.BaseName -eq $CustomProfile} | Select-Object -First 1

        if ($CustomProfileJson) {
            Write-Host -ForegroundColor DarkGray "Saving Module CustomProfile to $JsonPath"
            if (!(Test-Path "$ProgramDataOSDeploy")) {New-Item "$ProgramDataOSDeploy" -ItemType Directory -Force | Out-Null}
            Copy-Item -Path $CustomProfileJson.FullName -Destination $JsonPath -Force -ErrorAction Ignore
        }
    }
    #================================================
    #   Import Json
    #================================================
    if (Test-Path $JsonPath) {
        Write-Host -ForegroundColor DarkGray "Importing Configuration $JsonPath"
        $ImportAutopilotUtilities = @()
        $ImportAutopilotUtilities = Get-Content -Raw -Path $JsonPath | ConvertFrom-Json
    
        $ImportAutopilotUtilities.PSObject.Properties | ForEach-Object {
            if ($_.Value -match 'IsPresent=True') {
                $_.Value = $true
            }
            if ($_.Value -match 'IsPresent=False') {
                $_.Value = $false
            }
            if ($null -eq $_.Value) {
                Continue
            }
            Set-Variable -Name $_.Name -Value $_.Value -Force
        }
    }
    #================================================
    #   WinOS
    #================================================
    if ($env:SystemDrive -ne 'X:') {
        #================================================
        #   Set-PSRepository
        #================================================
        $PSGalleryIP = (Get-PSRepository -Name PSGallery).InstallationPolicy
        if ($PSGalleryIP -eq 'Untrusted') {
            Write-Host -ForegroundColor DarkGray "========================================================================="
            Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Set-PSRepository -Name PSGallery -InstallationPolicy Trusted"
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        }
        #================================================
        #   Dependency Check
        #================================================
        Write-Host -ForegroundColor DarkGray "Dependency Check"
        Test-MSGraph
        # Invoke-LoadModule Function by NEWBIEDEV
        function Invoke-LoadModule {
            [CmdletBinding()]
            param (
                [Parameter()]
                [string]
                $m
            )
            # If module is imported say that and do nothing
            if (Get-Module | Where-Object {$_.Name -eq $m}) {
                write-host "Module $m is already imported."
            }
            else {
        
                # If module is not imported, but available on disk then import
                if (Get-Module -ListAvailable | Where-Object {$_.Name -eq $m}) {
                    Import-Module $m -Verbose
                }
                else {
        
                    # If module is not imported, not available on disk, but is in online gallery then install and import
                    if (Find-Module -Name $m | Where-Object {$_.Name -eq $m}) {
                        Install-Module -Name $m -Force -Verbose -Scope CurrentUser
                        Import-Module $m -Verbose
                    }
                    else {
        
                        # If module is not imported, not available and not in online gallery then abort
                        write-host "Module $m not imported, not available and not in online gallery, exiting."
                        EXIT 1
                    }
                }
            }
        }
        Invoke-LoadModule AutopilotOOBE
<#        #================================================
        #   Test-AutopilotRecord
        #================================================
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Test-AutopilotRecord"
        Write-Host -ForegroundColor DarkCyan 'Gathering Autopilot Registration'
        if (Test-AutopilotRecord) {

        }#>
        #================================================
        #   Date Time
        #================================================
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Verify Date and Time"
        Write-Host -ForegroundColor DarkCyan 'Make sure the Time is set properly in the System BIOS as this can cause issues'
        Get-Date
        Get-TimeZone
        Start-Sleep -Seconds 5
        #================================================
        #   ApplyButton
        #================================================
        if ($env:UserName -ne 'defaultuser0') {
            Write-Warning 'The Apply button is disabled when the UserName is not defaultuser0'
            Start-Sleep -Seconds 5
        }
    }
    #================================================
    #   WinPE and WinOS Configuration Json
    #================================================
    $Global:AutopilotUtilities = [ordered]@{
        DeploymentGroup = $DeploymentGroup
        DeploymentGroupOptions = $DeploymentGroupOptions
        Assign = $Assign
        AssignedComputerName = $AssignedComputerName
        AssignedComputerNameExample = $AssignedComputerNameExample
        Disabled = $Disabled
        GroupTag = $GroupTag
        GroupTagOptions = $GroupTagOptions
        DeleteIntune = $deleteIntune
        DeleteAutopilot = $deleteAutopilot
        DeleteAzure = $deleteAzure
        Hidden = $Hidden
        PostAction = $PostAction
        Run = $Run
        Docs = $Docs
        Title = $Title
    }
    if ($env:SystemDrive -eq 'X:') {
        if (!(Test-Path "$ProgramDataOSDeploy")) {New-Item "$ProgramDataOSDeploy" -ItemType Directory -Force | Out-Null}
        Write-Host -ForegroundColor DarkGray "Exporting Configuration $ProgramDataOSDeploy\OSDeploy.AutopilotUtilities.json"
        @($Global:AutopilotUtilities.Keys) | ForEach-Object { 
            if (-not $Global:AutopilotUtilities[$_]) { $Global:AutopilotUtilities.Remove($_) }
        }
        $Global:AutopilotUtilities | ConvertTo-Json | Out-File "$ProgramDataOSDeploy\OSDeploy.AutopilotUtilities.json" -Force
    }
    else {
        Write-Host -ForegroundColor DarkGray "Exporting Configuration $env:Temp\OSDeploy.AutopilotUtilities.json"
        @($Global:AutopilotUtilities.Keys) | ForEach-Object { 
            if (-not $Global:AutopilotUtilities[$_]) { $Global:AutopilotUtilities.Remove($_) }
        }
        $Global:AutopilotUtilities | ConvertTo-Json | Out-File "$env:Temp\OSDeploy.AutopilotUtilities.json" -Force
        #================================================
        #   Launch
        #================================================
        Write-Host -ForegroundColor DarkGray "========================================================================="
        Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Starting AutopilotUtilities GUI"
        Start-Sleep -Seconds 1
        & "$($MyInvocation.MyCommand.Module.ModuleBase)\Project\MainWindow.ps1"
        #================================================
    }
}