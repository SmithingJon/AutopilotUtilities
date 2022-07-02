function Test-MSGraph {
    if (!(Import-Module Microsoft.Graph.Intune)){
        Write-Host "Installing MSGraph Powershell Module"
        Install-Module Microsoft.Graph.Intune -Force
    }
    Try {
        Get-MSGraphMetadata -ErrorAction Throw
    }
    Catch {
        Write-Host "MS Graph not Authenticated"
        Connect-MSGraph | Out-Null
    }
}