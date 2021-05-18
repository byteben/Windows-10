$Path = "HKLM:\Software\Microsoft\!ProactiveRemediations"
$Name = "20H2NotificationSchTaskCreated"
$Value = 1

$TargetDate = (Get-Date -Day 18 -Month 5 -Year 2021).ToString("ddMMyyy")
$ClientDate = (Get-Date).ToString("ddMMyyy")

If (!($TargetDate -eq $ClientDate)){
    Write-Output "Remediation Target Date""$($TargetDate)"" not valid. Client date is $ClientDate. Remediation will not run."
    Exit 0
}

Try {
    $Registry = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $Name
    If ($Registry -eq $Value){
        Write-Output "Registry Value is 1. Remediation will not run."
        Exit 0
    } 
    Write-Output "Registry Value is not 1. Remediation will run."
    Exit 1
} 
Catch {
    Write-Warning "Error Caught. Remediation will not run."
    Exit 0
}
