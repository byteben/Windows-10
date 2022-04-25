param (
    [Parameter(Mandatory = $true)]
    [string]$VMName

)

################CHOP IT################

$Generation = 2
$HDDSize = 30GB
$ProcessorCount = 2
$StartupMEM = 4096MB
$VMPath = "C:\MMSLABS\QuickVM"
$VirtualSwitchName = "WAN"
$ISOPath = "C:\MMSLABS\ISO\W1121H2.iso"
$VHDXPath = (Join-Path -Path $VMPath -ChildPath $VMName) + ".vhdx"

################COOK IT################

#Create VM
New-VM -Name $VMName -Path $VMPath -MemoryStartupBytes $StartupMEM -SwitchName $VirtualSwitchName -Generation $Generation

#Change Processor Count
Set-VMProcessor -VMName $VMName -Count $ProcessorCount

#Create VHD
New-VHD -Path $VHDXPath -SizeBytes $HDDSize -Dynamic
Add-VMHardDiskDrive -VMName $VMName -Path $VHDXPath

#Attach ISO
Add-VMDvdDrive -VMName  $VMName -Path $ISOPath

#Change Boot Order
$BootDVD = Get-VMFirmware $VMName | Select-Object -ExpandProperty BootOrder | where-object { $_.Device -like "DVD*" }
$BootHDD = Get-VMFirmware $VMName | Select-Object -ExpandProperty BootOrder | where-object { $_.Device -like "HardDiskDrive*" }
$BootPXE = Get-VMFirmware $VMName | Select-Object -ExpandProperty BootOrder | where-object { $_.Device -like "VMNetwork*" }
Set-VMFirmware -VMName $VMName -BootOrder $BootHDD, $BootDVD, $BootPXE

#Enable TPM
Set-VMKeyProtector -VMName $VMName -NewLocalKeyProtector
Enable-VMTPM -VMName $VMName

################CRANK IT################

#Start VM
Start-VM -Name $VMName