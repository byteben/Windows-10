<#
.Synopsis
Created on:   10/04/2021
Created by:   Ben Whitmore
Filename:     Uninstall_SetupComplete.ps1

.Description
Script to uninstall a custom SetupComplete.cmd which will be used POSTOOBE when installing a Feautre Update using Windows Update.

$env:SystemDrive\ProgramData\FeatureUpdate\<version>\ will be removed
$env:SystemDrive\Users\Default\AppData\Local\Microsoft\Windows\WSUS\SetupConfig.ini will be removed if the following line is present in SetupConfig.ini "PostOOBE=$env:SystemDrive\ProgramData\FeatureUpdate\<version>\SetupComplete.cmd"
#>

#Setup environment
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$SetupCompleteVersionFile = Join-Path -Path $ScriptPath -ChildPath "Version.txt"

#Get intended Version of SetupComplete
Try {
    If (Test-Path -Path $SetupCompleteVersionFile) {
        $SetupCompleteVersion = Get-Content $SetupCompleteVersionFile
        $SetupCompleteLocation = Join-Path -Path "$($env:SystemDrive)\ProgramData\FeatureUpdate" -ChildPath $SetupCompleteVersion
    }
}
Catch {
    Write-Host "Error getting SetupComplete Version from Script Source Directory. Does version.txt exist?"
}
  
Try {

    #Remove Directory
    Remove-Item $SetupCompleteLocation -Force -Recurse
}
Catch {
    Write-Host "Error removing ""$($SetupCompleteLocation)"""
}

#Remove SetupConfig.ini
Try {
    $iniFilePath = "$($env:SystemDrive)\Users\Default\AppData\Local\Microsoft\Windows\WSUS\SetupConfig.ini"
    if (Test-Path -Path $iniFilePath) {
        $SetupConfigini_Content = Get-Content $iniFilePath
        foreach ($line in $SetupConfigini_Content) { 
            If ($line -like "PostOOBE=$($SetupCompleteLocation)\SetupComplete.cmd") {
                Remove-Item $iniFilePath -Force
            }
        } 
    }
}
Catch {
    Write-Host "Error removing ""$($iniFilePath)"""
}