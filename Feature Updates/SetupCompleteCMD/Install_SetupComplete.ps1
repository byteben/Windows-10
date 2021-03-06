<#
.Synopsis
Created on:   10/04/2021
Created by:   Ben Whitmore
Filename:     Install_SetupComplete.ps1

.Description
Script to install a custom SetupComplete.cmd which will be used POSTOOBE when installing a Feautre Update using Windows Update.
Files in the "Files" source folder should resemble the structure from the root $env:SystemDrive

e.g. If you want to copy custom account pictures to your device after the OOBE they should be placed in ..\Files\ProgramData\Microsoft\User Account Pictures

Version.txt should contain the current version of SetupComplete.cmd. The application is designed with version control in mind. The version value will determine the path in $env:SystemDrive\ProgramData which the "FeatureUpdate" folder is created and the reference in SetupConfig.ini will also point to $env:SystemDrive\ProgramData\FeatureUpdate\<version>\SetupComplete.cmd
#>

#Setup environment
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$SetupCompleteVersionFile = Join-Path -Path $ScriptPath -ChildPath "Version.txt"

#Get intended Version of SetupComplete
Try {
    If (Test-Path -Path $SetupCompleteVersionFile) {
        $SetupCompleteVersion = Get-Content $SetupCompleteVersionFile
        $SetupCompleteLocation = Join-Path -Path "$($env:SystemDrive)\ProgramData\FeatureUpdate" -ChildPath $SetupCompleteVersion
        $SetupCompleteCMD = Join-Path -Path $SetupCompleteLocation -ChildPath "SetupComplete.cmd"
    }
}
Catch {
    Write-Host "Error getting SetupComplete Version from Script Source Directory. Does version.txt exist?"
}
  
Try {

    #Setup Directory and create SetupComplete.cmd
    New-Item $SetupCompleteLocation -ItemType Directory -Force 
    New-Item $SetupCompleteCMD -ItemType File -Force 

    #Add correct version of SetupComplete.ps1 to run post Feature Update
    Add-Content -Path $SetupCompleteCMD -Value "powershell.exe -executionpolicy bypass -file $($SetupCompleteLocation)\SetupComplete.ps1 -WindowStyle Hidden"
}
Catch {
    Write-Host "Error creating file ""$($SetupCompleteCMD)"""
}

Try {

    #Declare items to copy to Feature Update staging folder
    $SetupFiles = @("SetupComplete.ps1", "Files", "Version.txt")

    #Copy Files from Script Root to Feature Update staging folder
    Foreach ($File in $SetupFiles) {
        $FiletoCopy = Join-Path -Path $ScriptPath -ChildPath $File -ErrorAction SilentlyContinue
        Try {
            Copy-Item -Path $FiletoCopy -Destination $SetupCompleteLocation -Force -Recurse
        }
        Catch {
            Write-Warning: "Error copying item ""$($File)"" to ""$($SetupCompleteLocation)"""
        } 
    }
}
Catch {
    Write-Warning "Error setting up the Feature Update staging folder"
}

#Create SetupConfig.ini
#Source https://docs.microsoft.com/en-us/windows/deployment/update/feature-update-user-install#step-2-override-the-default-windows-setup-priority-windows-10-version-1709-and-later

#Variables for SetupConfig
$iniFilePath = "$env:SystemDrive\Users\Default\AppData\Local\Microsoft\Windows\WSUS\SetupConfig.ini"
$PriorityValue = "Normal"

$iniSetupConfigSlogan = "[SetupConfig]"
$iniSetupConfigKeyValuePair = @{"Priority" = $PriorityValue; "PostOOBE" = $SetupCompleteCMD }

#Init SetupConfig content
$iniSetupConfigContent = @"
$iniSetupConfigSlogan
"@

Try {

    #Setup SetupConfig Directory
    #Build SetupConfig content with settings
    foreach ($k in $iniSetupConfigKeyValuePair.Keys) {
        $val = $iniSetupConfigKeyValuePair[$k]
        $iniSetupConfigContent = $iniSetupConfigContent.Insert($iniSetupConfigContent.Length, "`r`n$k=$val")
    }

    #Write content to file 
    New-Item $iniFilePath -ItemType File -Value $iniSetupConfigContent -Force
}
Catch {
    Write-Warning "Error creating ""$($iniFilePath)"""
}