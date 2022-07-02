#================================================
#   Functions
#   https://github.com/RamblingCookieMonster/PSStackExchange/blob/master/PSStackExchange/PSStackExchange.psm1
#================================================
$AutoPilotUtilitiesPublicFunctions  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$AutoPilotUtilitiesPrivateFunctions = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

foreach ($Import in @($AutoPilotUtilitiesPublicFunctions + $AutoPilotUtilitiesPrivateFunctions)) {
    Try {. $Import.FullName}
    Catch {Write-Error -Message "Failed to import function $($Import.FullName): $_"}
}

Export-ModuleMember -Function $AutoPilotUtilitiesPublicFunctions.BaseName
#================================================
#   Alias
#================================================
New-Alias -Name AutoPilotUtilities -Value Start-AutoPilotUtilities -Force -ErrorAction SilentlyContinue
Export-ModuleMember -Function Start-AutoPilotUtilities -Alias AutoPilotUtilities