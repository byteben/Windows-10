<#
.Synopsis
Created on:   31/12/2021
Created by:   Ben Whitmore
Filename:     Install-Printer.ps1

Simple script to install a network printer from an INF file. The INF and required CAB files hould be in the same directory as the script if creating a Win32app

#### Win32 app Commands ####

Install:
powershell.exe -executionpolicy bypass -file .\Install-Printer.ps1 -PortName "IP_10.10.1.1" -PrinterIP "10.1.1.1" -PrinterName "Canon Printer Upstairs" -DriverName "Canon Generic Plus UFR II" -INFFile "CNLB0MA64.inf"

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

function Write-LogEntry {
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Value,
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$FileName = $PrinterName
    )

    #Build Log File appending System Date/Time to output
    $LogFile = Join-Path -Path $env:SystemRoot -ChildPath $("Temp\$FileName")
    $Time = -join @((Get-Date -Format "HH:mm:ss.fff"), " ", (Get-WmiObject -Class Win32_TimeZone | Select-Object -ExpandProperty Bias))
    $Date = (Get-Date -Format "MM-dd-yyyy")
    $LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"">"
	
    Try {
        Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFile -ErrorAction Stop
        Write-Verbose -Message $Value
    }
    Catch [System.Exception] {
        Write-Warning -Message "Unable to add log entry to $LogFile.log file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

Write-LogEntry -Value "Install Printer using the following values..."
Write-LogEntry -Value "Port Name: $PortName"
Write-LogEntry -Value "Printer IP: $PrinterIP"
Write-LogEntry -Value "Printer Name: $PrinterName"
Write-LogEntry -Value "Driver Name: $DriverName"
Write-LogEntry -Value "INF File: $INFFile"

$INFARGS = @(
    "/add-driver"
    "$INFFile"
)

Try {

    #Add driver to driver store
    Write-LogEntry -Value"Adding Driver to Windows DriverStore using INF ""$($INFFile)"""
    Write-LogEntry -Value "Running command: Start-Process C:\Windows\sysnative\pnputil.exe -ArgumentList $($INFARGS) -wait -passthru"
    Start-Process "C:\Windows\sysnative\pnputil.exe" -ArgumentList $INFARGS -wait -passthru
    
    #Install driver
    $DriverExist = Get-Printerport -Name $DriverName -ErrorAction SilentlyContinue
    if (-not $DriverExist) {
        Write-Output "Adding Printer Driver ""$($DriverName)"""
        Add-PrinterDriver -Name $DriverName -Confirm:$false
    }
    else {
        Write-LogEntry -Value "Print Driver ""$($DriverName)"" already exists. Skipping driver installation."
    }

    #Create Printer Port
    $PortExist = Get-Printerport -Name $PortName -ErrorAction SilentlyContinue
    if (-not $PortExist) {
        Write-LogEntry -Value "Adding Port ""$($PortName)"""
        Add-PrinterPort -name $PortName -PrinterHostAddress $PrinterIP -Confirm:$false
    }
    else {
        Write-LogEntry -Value "Port ""$($PortName)"" already exists. Skipping Printer Port installation."
    }

    #Add Printer
    $PrinterExist = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
    if (-not $PrinterExist) {
        Write-LogEntry -Value "Adding Printer ""$($PrinterName)"""
        Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName -Confirm:$false
    }
    else {
        Write-LogEntry -Value "Printer ""$($PrinterName)"" already exists. Removing old printer..."
        Remove-Printer -Name $PrinterName -Confirm:$false
        Write-LogEntry -Value "Adding Printer ""$($PrinterName)"""
        Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName -Confirm:$false
    }
}
Catch {
    Write-Warning "`nError during installation.."
    Write-Warning "$($_.Exception.Message)"
    Write-LogEntry -Value "$($_.Exception.Message)"
}