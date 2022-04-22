$VMName = "AP0001"
$Generation = 2
$HDDSize = 30GB
$ProcessorCount = 2
$StartupMEM = 4096MB
$VMPath = "C:\MY_VM_LAB"
$VirtualSwitchName = "WAN"
$ISOPath = "C:\LabSources\ISOs\en-us_windows_11_business_editions_version_21h2_updated_october_2021_x64_dvd_320e70b4.iso"
$VHDXPath = (Join-Path -Path $VMPath -ChildPath $VMName) + ".vhdx"
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
Start-VM -Name $VMName