<#	
===========================================================================
	 Created on:   	04/07/2020 13:06
	 Created by:   	Ben Whitmore
	 Organization: 	-
	 Filename:     	Uninstall_Font.ps1
===========================================================================
    
Version:
1.0

#>

#Set Current Directory
$ScriptPath = $MyInvocation.MyCommand.Path
$CurrentDir = Split-Path $ScriptPath

#Set Font Reg Key Path
$FontRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

#Grab the Font from the Current Directory
foreach ($File in $(Get-ChildItem -Path $CurrentDir -Include *.ttf, *.otf, *.fon, *.fnt -Recurse)) {

    #Remove the Font from the Windows Font Directory
    Remove-Item (Join-Path "C:\Windows\Fonts\" $File.Name) -Force | Out-Null

    #Remove the corresponding Registry Key
    Remove-ItemProperty -Path $FontRegPath -Name $File.Name | Out-Null
}