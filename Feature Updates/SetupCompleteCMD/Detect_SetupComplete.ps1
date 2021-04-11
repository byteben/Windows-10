<#
.Synopsis
Created on:   10/04/2021
Created by:   Ben Whitmore
Filename:     Detect_SetupComplete.ps1

.Description
Detection script to be deployed with ConfigMgr to detect SetupComplete.cmd in $env:SystemDrive\ProgramData\FeatureUpdate\<version>\SetupComplete.cmd and to check SetupCOnfig.ini references the correct version of the application i.e. $env:SystemDrive\Users\Default\AppData\Local\Microsoft\Windows\WSUS\SetupConfig.ini POSTOOBE will reference SetupComplete.cmd as outlined above
#>

$SetupCompleteVersion = "1.09.04"
$SetupCompleteLocation = Join-Path -Path "$($env:SystemDrive)\ProgramData\FeatureUpdate" -ChildPath $SetupCompleteVersion

$FUFilesInComplete = $Null
$SetupConfigini_Valid = $Null

Try {
	If (!(Test-Path -Path $SetupCompleteLocation)) {
		$FUFilesInComplete = $True
	}
}
Catch {
	$FUFilesInComplete = $True
}

Try {
	$iniFilePath = "$($env:SystemDrive)\Users\Default\AppData\Local\Microsoft\Windows\WSUS\SetupConfig.ini"
	if (Test-Path -Path $iniFilePath) {
		$SetupConfigini_Content = Get-Content $iniFilePath
		foreach ($line in $SetupConfigini_Content) { 
			If ($line -like "PostOOBE=$($SetupCompleteLocation)\SetupComplete.cmd") {
				$SetupConfigini_Valid = $True
			}
		} 
	}
	else {
		$FUFilesInComplete = $True
	}
}
Catch {
	$FUFilesInComplete = $True
}

If (($SetupConfigini_Valid) -and (!($FUFilesInComplete))) {
	Write-Output "Installed"
}