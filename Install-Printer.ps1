<#
.Synopsis
Created on:   01/12/2021
Created by:   Ben Whitmore
Filename:     Install-Printer.ps1

Simple script to install a network printer from an INF file. The INF and required CAB files hould be in the same directory as the script if creating a Win32app

#### Win32App Commands ####

Install:
powershell.exe -executionpolicy bypass -file .\Install-Printer.ps1 -PortName "IP_10.10.1.1" -PrinterIP = "10.1.1.1" -PrinterName = "Canon Printer Upstairs" -DriverName = "Canon Generic Plus UFR II" -INFFile = "CNLB0MA64.inf"

Uninstall:
cmd /c

Detection:
HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Print\Printers\Canon Printer Upstairs
Name = "Canon Printer Upstairs"

.Example
.\Install-Printer.ps1 -PortName "IP_10.10.1.1" -PrinterIP "10.1.1.1" -PrinterName "Canon Printer Upstairs" -DriverName "Canon Generic Plus UFR II" -INFFile "CNLB0MA64.inf"
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
$LOGDIR = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"
$LOGStrip = $PrinterName -replace '\s', ''
$LOGName = "Printer_$($LOGStrip).log"
$LOGFile = Join-Path -Path $LOGDIR -ChildPath $LOGName

Start-Transcript -Path $LogFile

$INFARGS = @(
    "/install"
    "/add-driver"
    $INFFile
)

Try {
    #Add driver to driver store
    Write-Output "Adding Driver to Windows DriverStore using INF""$($INFFILE)"""
    Start-Process pnputil.exe -ArgumentList $INFARGS -Wait -NoNewWindow

    #Install driver
    $DriverExist = Get-Printerport -Name $DriverName -ErrorAction SilentlyContinue
    if (-not $DriverExist) {
        Write-Output "Adding Printer Driver""$($DriverName)"""
        Add-PrinterDriver -Name $DriverName -Confirm:$false
    }
    else {
        Write-Output "Print Driver ""$($DriverName)"" already exists. Skipping driver installation."
    }

    #Create Printer Port
    $PortExist = Get-Printerport -Name $PortName -ErrorAction SilentlyContinue
    if (-not $PortExist) {
        Write-Output "Adding Port""$($PortName)"""
        Add-PrinterPort -name $PortName -PrinterHostAddress $PrinterIP -Confirm:$false
    }
    else {
        Write-Output "Port ""$($PortName)"" already exists. Skipping Printer Port installation."
    }

    #Add Printer
    $PrinterExist = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
    if (-not $PrinterExist) {
        Write-Output "Adding Printer ""$($PrinterName)"""
        Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName -Confirm:$false
    }
    else {
        Write-Output "Printer ""$($PrinterName)"" already exists. Removing old printer..."
        Remove-Printer -Name $PrinterName -Confirm:$false
        Write-Output "Adding Printer ""$($PrinterName)"""
        Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName -Confirm:$false
    }
}
Catch {
    Write-Warning "`nError during installation.."
    $err = $_.Exception.Message
    Write-Error $err
}
Stop-Transcript