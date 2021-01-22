<#	
===========================================================================
	 Created on:   	0/01/2021 13:06
	 Created by:   	Ben Whitmore
	 Organization: 	-
	 Filename:     	Install_Flash_Removal_KB4577586.ps1
	 Target System: Windows 10 , Windows Server 2012/R2 | 2016 | 2019 | 1903 | 1909 | 2004
===========================================================================
    
Version:
1.2.1 - 22/01/2021
Added support for Server OS - Thanks @Hoorge for the suggestion

1.2 - 04/01/2021
Fixed 20H2 coding error - Credit @AndyUpperton

1.1 02/01/2021
Basic Transcript Logging added

1.0 - 01/01/2021
Release
#>

#Set Current Directory
$ScriptPath = $MyInvocation.MyCommand.Path
$CurrentDir = Split-Path $ScriptPath

$Log = Join-Path $ENV:TEMP "Flash_Uninstall.log"
Start-Transcript $Log

#Set WUSA.EXE Variable
$WUSA = "$env:systemroot\System32\wusa.exe"

#Get OS Product Name
$OS_ProductName = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion' ProductName).ProductName

#Build OS Version String
Switch ($OS_ProductName) {
	{ $_.StartsWith("Windows 10") } { $OS_String = ($OS_ProductName -split "\s+" | Select-Object -First 2) -Join ' ' }
	{ $_.StartsWith("Windows Server 2012 R2") } { $OS_String = ($OS_ProductName -split "\s+" | Select-Object -First 4) -Join ' ' }
	{ ($_.StartsWith("Windows Server") -and (!($_.Contains("R2")))) } { $OS_String = ($OS_ProductName -split "\s+" | Select-Object -First 3) -Join ' ' }
}

#Get OS Release ID for valid OS's
If (!($OS_String -match "Server 2012")) {
	$OS_ReleaseID = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion' ReleaseId).ReleaseId
}
else {
	Write-Output "Skipping check of Release ID for $($OS_ProductName)"
}

#Rename $OS_ReleaseID variable for "Windows 10 20H2" and "Windows Server, version 1909" because the same KB update is used for both 2004 and 2009
If (($OS_ReleaseID -eq "2009" -and $OS_ProductName -match "Windows 10")) {
	$OS_ReleaseID = "2004"
}

#Build OS Version Name variable
Switch ($OS_String) {
	{ $_.Equals("Windows 10") } { $Version_String = $OS_String + " Version " + $OS_ReleaseID }
	{ $_.StartsWith("Windows Server 2") } { $Version_String = $OS_String }
	{ $_.StartsWith("Windows Server,") } { $Version_String = $OS_String + $OS_ReleaseID }
}

#Get OS Architecture
$OS_Architecture = Switch (Get-CIMInstance -Namespace "ROOT\CIMV2" -Class "Win32_Processor" | Select-Object -Unique -ExpandProperty Architecture) {
	9 { 'x64-based' }
	0 { 'x86-based' }
	5 { 'ARM64-based' }
}

$PatchRequired = "Update for Removal of Adobe Flash Player for " + $Version_String + " for " + $OS_Architecture + " systems (KB4577586)"

#Get Patch Titles
$PatchNames = Get-ChildItem $CurrentDir | Where-Object { $_.PSIsContainer } | Foreach-Object { $_.Name }

#Check if the patch has been downloaded for the current system
$PatchFound = $False

#Check Installation
$Patch = Get-Hotfix | Where-Object { $_.HotFixID -match "KB4577586" }
If ($Patch) {
	Write-Host "Patch Already Installed"
}
else {

	Foreach ($Patch in $PatchNames) {
		If ($Patch -eq $PatchRequired) {
			$PatchFound = $True

			#Get MSU from the correct Directory
			$MSU = Get-ChildItem (Join-Path $CurrentDir $Patch) -Recurse | Where-Object { $_.Extension -eq ".msu" }
			$MSUFullPath = Join-Path (Join-Path $CurrentDir $PatchRequired) $MSU.Name

			#Set WUSA Args
			$Args = @(
				"""$MSUFullPath"""
				"/quiet"
				"/norestart"
			)
		}
	}

	#Patch detection determines outcome
	If ($PatchFound) {
		Write-Host "Patch found for this system"
		Write-Host "Patch Required: $($PatchRequired)"
		Write-Host "Patch Name: $($MSU.Name)"
		Write-Host "Installing Update..."

		#Install Patch
		Start-Process -FilePath $WUSA -ArgumentList $Args -Wait

		#Check Installation
		$Patch = Get-Hotfix | Where-Object { $_.HotFixID -match "KB4577586" }
		If ($Patch) {
			Write-Host "Patch Installed Successfully"
		}
		else {
			Write-Warning "Patch Installation Failed"
		}
	}
	else {
		Write-Host "Patch not found for this system"
		Write-Host "Patch Required: $($PatchRequired)"
	}
}
Stop-Transcript