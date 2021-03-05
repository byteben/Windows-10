$Patch = Get-Hotfix | Where-Object { $_.HotFixID -match "KB4577586" }
If ($Patch) {
    Write-Host "Installed"
}
else {
}