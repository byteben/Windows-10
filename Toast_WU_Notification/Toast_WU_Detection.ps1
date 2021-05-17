$Path = "HKLM:\Software\Microsoft\!ProactiveRemediations"
$Name = "20H2NotificationSchTaskCreated"
$Type = "DWORD"
$Value = 1

$TargetDate = Get-Date -Day 18 -Month 5 -Year 2021
$ClientDate = Get-Date

If (!($TargetDate -eq $ClientDate)){
    Write-Output "Remediation Script to run on ""$($TargetDate)"" but actual date is ""$($ClientDate)"". Remediation will not run."
    Exit 0
}

Try {
    $Registry = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop | Select-Object -ExpandProperty $Name
    If ($Registry -eq $Value){
        Write-Output "Registry Value is 1. Remediation will not run."
        Exit 0
    } 
    Write-Warning "Registry Value is not 1. Remediation will run."
    Exit 1
} 
Catch {
    Write-Warning "Error Caught. Remediation will not run."
    Exit 0
}
