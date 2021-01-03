Try {
    $Patch = Get-Hotfix | Where-Object { $_.HotFixID -match "KB4577586" }
    If ($Patch) {
        Write-Output "Compliant"
        Exit 0
    } 
    Write-Warning "Not Compliant"
    Exit 1
} 
Catch {
    Write-Warning "Not Compliant"
    Exit 1
}