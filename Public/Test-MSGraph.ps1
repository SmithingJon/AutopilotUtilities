function Test-MSGraph {
    [CmdletBinding()]
    param (
        [switch]
        $output
    )
    if (!(Get-Module Microsoft.Graph.Intune)) {
        if (Import-Module Microsoft.Graph.Intune){
            Write-Verbose "Installing MSGraph Powershell Module"
            Install-Module Microsoft.Graph.Intune -Force
            Import-Module Microsoft.Graph.Intune -Force
        }
    }

    try {Write-Verbose "Testing MSGraph Connection"
        $Organization = (Invoke-MSGraphRequest -URL "https://graph.microsoft.com/v1.0/organization").value
            if ($Organization) {
                Write-Verbose "Connected to MSGraph at $($Organization.displayName)"
            }
    }
    catch {Write-Verbose "Connecting to MSGraph"
        Connect-MSGraph | Out-Null}
    if ($output) {
        $Organization
    }
}