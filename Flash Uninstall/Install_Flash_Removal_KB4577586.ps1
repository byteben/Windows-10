<#	
===========================================================================
	 Created on:   	0/01/2021 13:06
	 Created by:   	Ben Whitmore
	 Organization: 	-
	 Filename:     	Install_Flash_Removal_KB4577586.ps1
	 Target System: Windows 10 Only
===========================================================================
    
Version:
1.0
#>

#Set Current Directory
$ScriptPath = $MyInvocation.MyCommand.Path
$CurrentDir = Split-Path $ScriptPath

#Get OS Release ID
$OS_ReleaseID = Get-ItemProperty "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion" | Select-Object -ExpandProperty ReleaseID
$OS_ProductName = Get-ItemProperty "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion" | Select-Object -ExpandProperty ProductName

#Get OS Architecture
$OS_Architecture = Switch (Get-CIMInstance -Namespace "ROOT\CIMV2" -Class "Win32_Processor" | Select-Object -ExpandProperty Architecture) {
	9 { 'x64-based' }
	0 { 'x86-based' }
	5 { 'ARM64-based' }
}

#Build OS Version String
$OS_String = ($OS_ProductName -split "\s+" | Select-Object -First 2) -Join ' '

#Build Patch Name String
$PatchRequired = "Update for Removal of Adobe Flash Player for " + $OS_String + " Version " + $OS_ReleaseID + " for " + $OS_Architecture + " systems (KB4577586)"

#Get Patch Titles
$PatchNames = Get-ChildItem $CurrentDir | Where-Object { $_.PSIsContainer } | Foreach-Object { $_.Name }

#Check if the patch has been downloaded for the current system
$PatchFound = $False

Foreach ($Patch in $PatchNames) {
	If ($Patch -eq $PatchRequired) {
		$PatchFound = $True

		#Get MSU from correct Directory
		$MSUPath = Get-ChildItem (Join-Path $CurrentDir $Patch) -Recurse | Where-Object { $_.Extension -eq ".msu" }
	}
}

#Patch detection determines outcome
If ($PatchFound) {
	Write-Host "Patch found for this system"
	Write-Host "Patch Required: $($PatchRequired)"
	Write-Host "Patch Name: $($MSUPath.Name)"

}
else {
	Write-Host "Patch not found for this system"
	Write-Host "Patch Required: $($PatchRequired)"
	Write-Host "Current System: $($OS_String) $($OS_ReleaseID) $($OS_Architecture) PC"
}