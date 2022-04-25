param (
    [Parameter(Mandatory = $true)]
    [string]$VMName

)

#Dilithium Shopping List
$Generation = 2
$HDDSize = 30GB
$ProcessorCount = 2
$StartupMEM = 4096MB
$VMPath = "C:\MMSLABS\QuickVM"
$VirtualSwitchName = "WAN"
$ISOPath = "C:\MMSLABS\ISO\W1121H2.iso"
$VHDXPath = (Join-Path -Path $VMPath -ChildPath $VMName) + ".vhdx"

#MakeItSo
New-VM -Name $VMName -Path $VMPath -MemoryStartupBytes $StartupMEM -SwitchName $VirtualSwitchName -Generation $Generation
New-VHD -Path $VHDXPath -SizeBytes $HDDSize -Dynamic
Add-VMHardDiskDrive -VMName $VMName -Path $VHDXPath
Add-VMDvdDrive -VMName  $VMName -Path $ISOPath
$BootDVD = Get-VMFirmware $VMName | Select-Object -ExpandProperty BootOrder | where-object { $_.Device -like "DVD*" }
$BootHDD = Get-VMFirmware $VMName | Select-Object -ExpandProperty BootOrder | where-object { $_.Device -like "HardDiskDrive*" }
$BootPXE = Get-VMFirmware $VMName | Select-Object -ExpandProperty BootOrder | where-object { $_.Device -like "VMNetwork*" }
Set-VMFirmware -VMName $VMName -BootOrder $BootHDD, $BootDVD, $BootPXE
Set-VMProcessor -VMName $VMName -Count $ProcessorCount
Set-VMKeyProtector -VMName $VMName -NewLocalKeyProtector
Enable-VMTPM -VMName $VMName

#WeNeedMorePower
Start-VM -Name $VMName