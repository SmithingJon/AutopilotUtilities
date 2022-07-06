function Test-MSGraph {
    if (!(Get-Module Microsoft.Graph.Intune)) {
        if (Import-Module Microsoft.Graph.Intune){
            Write-Host "Installing MSGraph Powershell Module"
            Install-Module Microsoft.Graph.Intune -Force
        }
    }

    Try {
        Invoke-MSGraphRequest -URL "https://graph.microsoft.com/v1.0/me" -ErrorAction Throw
    }
    Catch {
        Write-Host "MS Graph not Authenticated"
        Connect-MSGraph | Out-Null
    }
}