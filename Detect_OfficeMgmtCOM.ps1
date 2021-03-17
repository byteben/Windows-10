$Path = "HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate"
$Name = "OfficeMgmtCOM"
$Type = "DWORD"
$Value = 0

Try {
    $Registry = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $Name
    If ($Registry -eq $Value) {
        Write-Output "Compliant"
        Exit 0
    }
    ElseIf ($Registry -eq $null) {
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
