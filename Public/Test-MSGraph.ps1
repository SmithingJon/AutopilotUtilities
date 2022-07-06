function Test-MSGraph {
    if (!(Get-Module Microsoft.Graph.Intune)) {
        if (Import-Module Microsoft.Graph.Intune){
            Write-Host "Installing MSGraph Powershell Module"
            Install-Module Microsoft.Graph.Intune -Force
        }
    }

    try {Invoke-MSGraphRequest -URL "https://graph.microsoft.com/v1.0/organization"}
    catch {Connect-MSGraph | Out-Null}

}