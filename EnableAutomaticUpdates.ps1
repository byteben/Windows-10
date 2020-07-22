$Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
$Name = "NoAutoUpdate"
$Type = "DWORD"
$Value = 0

Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value 