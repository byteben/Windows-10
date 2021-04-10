<#
.Synopsis
Created on:   10/04/2021
Created by:   Ben Whitmore
Filename:     SetupComplete.ps1

.Description
POST OOBE during a Windows 10 Feature Update, installed via Windows Update, will run $env:SystemDrive\ProgramData\FU\<version>\SetupComplete.cmd. SetupComplete.cmd calls SetupComplete.ps1

This script will copy files to the device that are replaced, or required, after a Feature Update has been installed. The destination folder structure should be maintained in the "Files" source directory for the application. e.g. If you want to copy custom account pictures to your device after the OOBE they should be place in ..\Files\ProgramData\Microsoft\User Account Pictures
#>

#Setup environment
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

#Copy Files from Script Root to FU staging folder     
Try {
    $FilestoCopy = Join-Path -Path $ScriptPath -ChildPath "Files"
    Robocopy.exe $FilestoCopy $env:systemdrive\ /e /z /r:5 /w:1 /eta
}
Catch {
    Write-Warning: "Error copying files to ""$($env:systemdrive)"""
}

#Do other stuff here...