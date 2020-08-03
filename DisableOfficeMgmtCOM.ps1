$Path = "HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate"
$Name = "OfficeMgmtCOM"
$Type = "DWORD"
$Value = 0

Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value 