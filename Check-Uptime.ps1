$Uptime = get-computerinfo | Select-Object OSUptime 
if ($Uptime.OsUptime.Days -ge 7) {
    Write-Output "Last reboot in days: $($Uptime.OsUptime.Days)"
    Exit 1
}
else {
    Write-Output "Last reboot in days: $($Uptime.OsUptime.Days)"
    Exit 0
}