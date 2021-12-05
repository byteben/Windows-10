<#
.Synopsis
Created on:   01/12/2021
Created by:   Ben Whitmore
Filename:     Install-Printer.ps1

Simple script to install a network printer from an INF file. The INF and required CAB files should be in the same directory as the script when creating a Win32app

#### Win32App Commands ####

Install:
powershell.exe -executionpolicy bypass -file .\Install-Printer.ps1 -PortName "IP_10.10.1.1" -PrinterIP = "10.1.1.1" -PrinterName = "Canon Printer Upstairs" -DriverName = "Canon Generic Plus UFR II" -INFFile = "CNLB0MA64.inf"

Uninstall:
cmd /c

Detection:
HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Print\Printers\Canon Printer Upstairs
Name = "Canon Printer Upstairs"

.Example
Install-Printer.ps1 -PortName "IP_10.10.1.1" -PrinterIP = "10.1.1.1" -PrinterName = "Canon Printer Upstairs" -DriverName = "Canon Generic Plus UFR II" -INFFile = "CNLB0MA64.inf"
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $True)]
    [String]$PortName,
    [Parameter(Mandatory = $True)]
    [String]$PrinterIP,
    [Parameter(Mandatory = $True)]
    [String]$PrinterName,
    [Parameter(Mandatory = $True)]
    [String]$DriverName,
    [Parameter(Mandatory = $True)]
    [String]$INFFile
)

$INFARGS = @(
    "-i"
    "-a"
    $INFFile
)

Try {
    #Add driver to driver store
    Start-Process pnputil.exe -ArgumentList $INFARGS -Wait -NoNewWindow

    #Install driver
    Add-PrinterDriver -Name $DriverName -Confirm:$false

    #Create Printer Port
    $PortExist = Get-Printerport -Name $PortName -ErrorAction SilentlyContinue
    if (-not $PortExist) {
        Add-PrinterPort -name $PortName -PrinterHostAddress $PrinterIP -Confirm:$false
    }

    #Add Printer
    Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName -Confirm:$false
}
Catch {
    Write-Warning "Error Installing Printer"
}